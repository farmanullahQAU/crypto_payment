import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/contract_service.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'invoices_screen.dart';
import 'create_invoice_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final ContractService _contractService = ContractService();
  final TextEditingController _rpcController = TextEditingController(
      text: AppConstants.defaultRpcUrl);
  final TextEditingController _publicAddressController = TextEditingController();

  String _userAddress = "";
  bool _isLoading = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRpc = prefs.getString(AppConstants.prefsRpcUrl) ?? AppConstants.defaultRpcUrl;
    final savedAddress = prefs.getString('public_address') ?? '';
    setState(() {
      _rpcController.text = savedRpc;
      _publicAddressController.text = savedAddress;
    });
  }

  Future<void> _connect() async {
    if (_rpcController.text.isEmpty || _publicAddressController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await _contractService.init(rpcUrl: _rpcController.text);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefsRpcUrl, _rpcController.text);
      await prefs.setString('public_address', _publicAddressController.text);

      setState(() {
        _userAddress = _publicAddressController.text;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection failed: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _disconnect() {
    setState(() {
      _userAddress = "";
    });
  }

  Widget _buildConnectScreen() {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet, size: 80, color: AppTheme.primaryColor),
              const SizedBox(height: 24),
              const Text(
                "Crypto Payment",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                "Connect your wallet to proceed",
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _rpcController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "RPC URL"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _publicAddressController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Public Wallet Address",
                  hintText: "0x...",
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _connect,
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Connect"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userAddress.isEmpty) {
      return _buildConnectScreen();
    }

    final screens = [
      DashboardScreen(contractService: _contractService, userAddress: _userAddress, onDisconnect: _disconnect),
      InvoicesScreen(contractService: _contractService, userAddress: _userAddress),
      CreateInvoiceScreen(contractService: _contractService, userAddress: _userAddress),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Invoices"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: "Create"),
        ],
      ),
    );
  }
}
