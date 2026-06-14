import 'package:flutter/material.dart';
import '../services/contract_service.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_card.dart';
import '../widgets/signature_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final ContractService contractService;
  final String userAddress;
  final VoidCallback onDisconnect;

  const DashboardScreen({
    Key? key,
    required this.contractService,
    required this.userAddress,
    required this.onDisconnect,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  Map<String, String> _walletBalances = {};
  Map<String, String> _platformBalances = {};

  final TextEditingController _depositController = TextEditingController();
  final TextEditingController _withdrawController = TextEditingController();
  final TextEditingController _p2pRecipientController = TextEditingController();
  final TextEditingController _p2pAmountController = TextEditingController();
  
  String _selectedActionToken = "Native DC";
  bool _isFamilyTransfer = false;

  @override
  void initState() {
    super.initState();
    _fetchBalances();
  }

  Future<void> _fetchBalances() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, String> newWallet = {};
      final Map<String, String> newPlatform = {};

      for (final token in AppConstants.supportedTokens) {
        final symbol = token['symbol'];
        final address = token['address'];
        final decimals = token['decimals'];

        final wBal = await widget.contractService.getERC20Balance(widget.userAddress, address);
        final pBal = await widget.contractService.getInternalLedgerBalance(widget.userAddress, address);

        final divisor = BigInt.from(10).pow(decimals);
        newWallet[symbol] = (wBal / divisor).toStringAsFixed(4);
        newPlatform[symbol] = (pBal / divisor).toStringAsFixed(4);
      }

      setState(() {
        _walletBalances = newWallet;
        _platformBalances = newPlatform;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to fetch balances: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String err) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppTheme.errorColor));
  }
  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.successColor));
  }

  Future<void> _handleDeposit() async {
    if (_depositController.text.isEmpty) return;
    
    final privateKey = await SignatureDialog.show(context);
    if (privateKey == null || privateKey.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final amount = double.parse(_depositController.text);
      final decimals = AppConstants.getDecimals(_selectedActionToken);
      final wei = BigInt.from(amount * double.parse("1" + "0" * (decimals - 1)) * 10);
      
      String tx;
      if (_selectedActionToken == "Native DC") {
        tx = await widget.contractService.depositETH(privateKey, wei);
      } else {
        tx = await widget.contractService.depositToken(privateKey, AppConstants.getAddress(_selectedActionToken), wei);
      }
      _showSuccess("Deposit successful. Hash: $tx");
      _depositController.clear();
      _fetchBalances();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleWithdraw() async {
    if (_withdrawController.text.isEmpty) return;
    
    final privateKey = await SignatureDialog.show(context);
    if (privateKey == null || privateKey.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final amount = double.parse(_withdrawController.text);
      final decimals = AppConstants.getDecimals(_selectedActionToken);
      final wei = BigInt.from(amount * double.parse("1" + "0" * (decimals - 1)) * 10);
      
      String tx;
      if (_selectedActionToken == "Native DC") {
        tx = await widget.contractService.withdrawETH(privateKey, wei);
      } else {
        tx = await widget.contractService.withdrawToken(privateKey, AppConstants.getAddress(_selectedActionToken), wei);
      }
      _showSuccess("Withdraw successful. Hash: $tx");
      _withdrawController.clear();
      _fetchBalances();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleP2PTransfer() async {
    if (_p2pRecipientController.text.isEmpty || _p2pAmountController.text.isEmpty) return;
    
    final privateKey = await SignatureDialog.show(context);
    if (privateKey == null || privateKey.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final tokenAddr = AppConstants.getAddress(_selectedActionToken);
      final decimals = AppConstants.getDecimals(_selectedActionToken);
      final amount = BigInt.from(double.parse(_p2pAmountController.text) * double.parse("1" + "0" * (decimals - 1)) * 10);
      
      final tx = await widget.contractService.transferToUser(
        privateKey: privateKey,
        recipient: _p2pRecipientController.text,
        token: tokenAddr,
        amount: amount,
        isFamilyTransfer: _isFamilyTransfer,
      );
      _showSuccess("Transfer successful. Hash: $tx");
      _p2pRecipientController.clear();
      _p2pAmountController.clear();
      _fetchBalances();
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
        title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchBalances),
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onDisconnect),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _fetchBalances,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAddressBanner(),
                  const SizedBox(height: 24),
                  _buildBalancesGrid(),
                  const SizedBox(height: 24),
                  _buildDepositWithdrawCard(),
                  const SizedBox(height: 24),
                  _buildP2PCard(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildAddressBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Connected Wallet", style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text(
                  widget.userAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalancesGrid() {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          BalanceCard(
            title: "Native DC",
            balance: _walletBalances["Native DC"] ?? "0.0",
            ledgerBalance: _platformBalances["Native DC"] ?? "0.0",
            icon: Icons.currency_bitcoin,
            accentColor: AppTheme.warningColor,
          ),
          BalanceCard(
            title: "USDT",
            balance: _walletBalances["USDT"] ?? "0.0",
            ledgerBalance: _platformBalances["USDT"] ?? "0.0",
            icon: Icons.attach_money,
            accentColor: AppTheme.successColor,
          ),
          BalanceCard(
            title: "USDC",
            balance: _walletBalances["USDC"] ?? "0.0",
            ledgerBalance: _platformBalances["USDC"] ?? "0.0",
            icon: Icons.monetization_on,
            accentColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildDepositWithdrawCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quick Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedActionToken,
              items: ["Native DC", "USDT", "USDC"]
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedActionToken = v!),
              decoration: const InputDecoration(labelText: "Select Token"),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _depositController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Deposit Amount", hintText: "0.0"),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _handleDeposit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                  child: const Text("Deposit"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _withdrawController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Withdraw Amount", hintText: "0.0"),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _handleWithdraw,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                  child: const Text("Withdraw"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildP2PCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("P2P Transfer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: _p2pRecipientController,
              decoration: const InputDecoration(labelText: "Recipient Address", hintText: "0x..."),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _p2pAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Amount", hintText: "0.0"),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _isFamilyTransfer,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (v) => setState(() => _isFamilyTransfer = v!),
                    ),
                    const Text("Family"),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleP2PTransfer,
                icon: const Icon(Icons.send),
                label: const Text("Send Funds"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
