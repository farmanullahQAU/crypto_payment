import 'package:flutter/material.dart';
import '../services/contract_service.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/signature_dialog.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final ContractService contractService;
  final String userAddress;

  const CreateInvoiceScreen({
    Key? key,
    required this.contractService,
    required this.userAddress,
  }) : super(key: key);

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final TextEditingController _payerController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _intervalController = TextEditingController();
  final TextEditingController _maxCyclesController = TextEditingController();

  String _selectedToken = "Native DC";
  int _selectedPaymentType = 0; // 0=PREPAID, 1=POSTPAID
  bool _isRecurring = false;
  bool _isLoading = false;

  void _showError(String err) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppTheme.errorColor));
  }
  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.successColor));
  }

  Future<void> _handleCreateInvoice() async {
    if (_payerController.text.isEmpty || _amountController.text.isEmpty) {
      _showError("Please fill required fields.");
      return;
    }

    final privateKey = await SignatureDialog.show(context);
    if (privateKey == null || privateKey.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final tokenAddr = AppConstants.getAddress(_selectedToken);
      final decimals = AppConstants.getDecimals(_selectedToken);
      
      final amountWei = BigInt.from(
        double.parse(_amountController.text) *
            double.parse("1" + "0" * (decimals - 1)) *
            10,
      );
      
      final now = BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000);
      final dueDate = now + BigInt.from(86400 * 7); // 7 days from now

      final rInterval = _isRecurring ? BigInt.parse(_intervalController.text) : BigInt.zero;
      final mCycles = _isRecurring ? BigInt.parse(_maxCyclesController.text) : BigInt.zero;

      final tx = await widget.contractService.createInvoice(
        privateKey: privateKey,
        payer: _payerController.text,
        token: tokenAddr,
        amount: amountWei,
        dueDate: dueDate,
        description: _descController.text.isEmpty ? "No Description" : _descController.text,
        paymentType: _selectedPaymentType,
        isRecurring: _isRecurring,
        recurringInterval: rInterval,
        maxCycles: mCycles,
      );

      _showSuccess("Invoice created! Tx Hash: $tx");
      
      _payerController.clear();
      _amountController.clear();
      _descController.clear();
      _intervalController.clear();
      _maxCyclesController.clear();
      setState(() {
        _isRecurring = false;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Invoice", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Invoice Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                TextField(
                  controller: _payerController,
                  decoration: const InputDecoration(labelText: "Payer Wallet Address", hintText: "0x..."),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedToken,
                        items: ["Native DC", "USDT", "USDC"]
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedToken = v!),
                        decoration: const InputDecoration(labelText: "Token"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: "Amount", hintText: "0.0"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: "Work / Product Description"),
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<int>(
                  value: _selectedPaymentType,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text("PREPAID (Escrow)")),
                    DropdownMenuItem(value: 1, child: Text("POSTPAID (Instant)")),
                  ],
                  onChanged: (v) => setState(() => _selectedPaymentType = v!),
                  decoration: const InputDecoration(labelText: "Payment Type"),
                ),
                const SizedBox(height: 20),
                
                SwitchListTile(
                  title: const Text("Recurring Billing"),
                  subtitle: const Text("Automatically bill at an interval"),
                  value: _isRecurring,
                  activeColor: AppTheme.primaryColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _isRecurring = v),
                ),
                
                if (_isRecurring) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _intervalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Interval (Seconds)", hintText: "86400"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _maxCyclesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Max Cycles", hintText: "12"),
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleCreateInvoice,
                  icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_circle),
                  label: Text(_isLoading ? "Processing..." : "Create Invoice"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
