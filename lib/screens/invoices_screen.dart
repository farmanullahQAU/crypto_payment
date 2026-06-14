import 'package:flutter/material.dart';
import '../services/contract_service.dart';
import '../models/invoice.dart';
import '../theme/app_theme.dart';
import '../widgets/invoice_card.dart';
import '../widgets/signature_dialog.dart';

class InvoicesScreen extends StatefulWidget {
  final ContractService contractService;
  final String userAddress;

  const InvoicesScreen({
    Key? key,
    required this.contractService,
    required this.userAddress,
  }) : super(key: key);

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  List<Invoice> _payerInvoices = [];
  List<Invoice> _merchantInvoices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchInvoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);
    try {
      final pIds = await widget.contractService.getPayerInvoices(widget.userAddress);
      final mIds = await widget.contractService.getMerchantInvoices(widget.userAddress);

      final pList = await Future.wait(pIds.map((id) => widget.contractService.getInvoice(id)));
      final mList = await Future.wait(mIds.map((id) => widget.contractService.getInvoice(id)));

      setState(() {
        _payerInvoices = pList.reversed.toList();
        _merchantInvoices = mList.reversed.toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to fetch invoices: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleInvoiceAction(Invoice inv, String action) async {
    final privateKey = await SignatureDialog.show(context);
    if (privateKey == null || privateKey.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      String txHash = "";
      final now = BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000);

      switch (action) {
        case "pay":
          if (inv.paymentType == 0) {
            txHash = await widget.contractService.payPrepaidInvoice(privateKey, inv.id, now + BigInt.from(3600));
          } else {
            txHash = await widget.contractService.payPostpaidInvoice(privateKey, inv.id, now + BigInt.from(3600));
          }
          break;
        case "reject":
          txHash = await widget.contractService.rejectInvoice(privateKey, inv.id, "Rejected by Payer");
          break;
        case "cancel":
          txHash = await widget.contractService.cancelInvoice(privateKey, inv.id, "Cancelled by Merchant");
          break;
        case "mark_complete":
          txHash = await widget.contractService.markComplete(privateKey, inv.id);
          break;
        case "confirm":
          txHash = await widget.contractService.confirmCompletion(privateKey, inv.id);
          break;
        case "dispute":
          txHash = await widget.contractService.raiseDispute(privateKey, inv.id, "Disputed by Payer");
          break;
        case "claim":
          txHash = await widget.contractService.claimPayment(privateKey, inv.id);
          break;
        case "reclaim":
          txHash = await widget.contractService.reclaimFunds(privateKey, inv.id);
          break;
        case "trigger":
          txHash = await widget.contractService.triggerRecurring(privateKey, inv.id);
          break;
        case "challenge":
          txHash = await widget.contractService.challengeDispute(privateKey: privateKey, invoiceId: inv.id, evidence: "Challenge Link");
          break;
        case "finalize":
          txHash = await widget.contractService.finalizeResolution(privateKey, inv.id);
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Success: $txHash"), backgroundColor: AppTheme.successColor));
      _fetchInvoices();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Action failed: $e"), backgroundColor: AppTheme.errorColor));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoices", style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: "My Bills (Payer)"),
            Tab(text: "My Sales (Merchant)"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_payerInvoices, false),
                _buildList(_merchantInvoices, true),
              ],
            ),
    );
  }

  Widget _buildList(List<Invoice> list, bool isMerchant) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            const Text("No invoices found", style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchInvoices,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: list.length,
        itemBuilder: (context, i) {
          return InvoiceCard(
            invoice: list[i],
            isMerchant: isMerchant,
            onAction: (action) => _handleInvoiceAction(list[i], action),
          );
        },
      ),
    );
  }
}
