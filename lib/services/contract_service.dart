import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';
import '../models/invoice.dart';

class ContractService {
  late Web3Client _web3client;
  late DeployedContract _platformContract;
  late DeployedContract _erc20Contract;

  final String contractAddressHex =
      "0xC93ABa2273C47e0f8298FD49Cd193B8B045cD631";
  final String defaultRpcUrl = "https://rpc.testnet.dailycrypto.net";

  bool _initialized = false;
  bool get initialized => _initialized;

  Future<void> init({required String rpcUrl}) async {
    _web3client = Web3Client(rpcUrl.isEmpty ? defaultRpcUrl : rpcUrl, Client());

    // Load ABI from assets
    final abiString = await rootBundle.loadString(
      'assets/CryptoPaymentPlatform.json',
    );
    final abiJson = json.decode(abiString);
    final abiVal = abiJson is Map ? abiJson['abi'] : abiJson;

    _platformContract = DeployedContract(
      ContractAbi.fromJson(json.encode(abiVal), 'CryptoPaymentPlatform'),
      EthereumAddress.fromHex(contractAddressHex),
    );

    // Standard ERC20 ABI for approving tokens
    final erc20AbiString = await rootBundle.loadString('assets/erc20_abi.json');
    final erc20AbiJson = json.decode(erc20AbiString);
    
    _erc20Contract = DeployedContract(
      ContractAbi.fromJson(json.encode(erc20AbiJson), 'ERC20'),
      EthereumAddress.fromHex(
        "0x0000000000000000000000000000000000000000",
      ), // Placeholder, we will bind as needed
    );

    _initialized = true;
  }

  // Get credentials from private key
  EthPrivateKey getCredentials(String privateKey) {
    return EthPrivateKey.fromHex(privateKey.trim());
  }

  Future<String> getAddressFromPrivateKey(String privateKey) async {
    final creds = getCredentials(privateKey);
    return creds.address.eip55With0x;
  }

  // Helper to call view functions
  Future<List<dynamic>> _readContract(
    String functionName,
    List<dynamic> params,
  ) async {
    final function = _platformContract.function(functionName);
    return _web3client.call(
      contract: _platformContract,
      function: function,
      params: params,
    );
  }

  // Helper to send transactions
  Future<String> _writeContract(
    String privateKey,
    String functionName,
    List<dynamic> params, {
    EtherAmount? value,
  }) async {
    final credentials = getCredentials(privateKey);
    final function = _platformContract.function(functionName);
    final chainId = await _web3client.getChainId();

    return _web3client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: _platformContract,
        function: function,
        parameters: params,
        value: value,
        maxGas: 3000000,
      ),
      chainId: chainId.toInt(),
    );
  }

  // --- View Functions ---

  Future<EtherAmount> getNativeBalance(String addressHex) async {
    return _web3client.getBalance(EthereumAddress.fromHex(addressHex));
  }

  Future<BigInt> getERC20Balance(
    String userAddressHex,
    String tokenAddressHex,
  ) async {
    if (tokenAddressHex == "0x0000000000000000000000000000000000000000") {
      final bal = await getNativeBalance(userAddressHex);
      return bal.getInWei;
    }
    final contract = DeployedContract(
      _erc20Contract.abi,
      EthereumAddress.fromHex(tokenAddressHex),
    );
    final function = contract.function('balanceOf');
    final response = await _web3client.call(
      contract: contract,
      function: function,
      params: [EthereumAddress.fromHex(userAddressHex)],
    );
    return response.first as BigInt;
  }

  Future<BigInt> getInternalLedgerBalance(
    String userAddressHex,
    String tokenAddressHex,
  ) async {
    final res = await _readContract('balanceOf', [
      EthereumAddress.fromHex(userAddressHex),
      EthereumAddress.fromHex(tokenAddressHex),
    ]);
    return res.first as BigInt;
  }

  Future<Invoice> getInvoice(BigInt id) async {
    final res = await _readContract('getInvoice', [id]);
    final tuple = res.first as List<dynamic>;
    return Invoice(
      id: tuple[0] as BigInt,
      payer: (tuple[1] as EthereumAddress).eip55With0x,
      merchant: (tuple[2] as EthereumAddress).eip55With0x,
      token: (tuple[3] as EthereumAddress).eip55With0x,
      amount: tuple[4] as BigInt,
      dueDate: tuple[5] as BigInt,
      description: tuple[6] as String,
      paymentType: (tuple[7] as int),
      status: (tuple[8] as int),
      isRecurring: tuple[9] as bool,
      recurringInterval: tuple[10] as BigInt,
      maxCycles: tuple[11] as BigInt,
      completedCycles: tuple[12] as BigInt,
      nextDueDate: tuple[13] as BigInt,
      createdAt: tuple[14] as BigInt,
      payerAcknowledged: tuple[15] as bool,
    );
  }

  Future<List<BigInt>> getMerchantInvoices(String merchantHex) async {

    final res = await _readContract('getMerchantInvoices', [
      EthereumAddress.fromHex(merchantHex),
    ]);
    return (res.first as List<dynamic>).cast<BigInt>();
  }

  Future<List<BigInt>> getPayerInvoices(String payerHex) async {
    final res = await _readContract('getPayerInvoices', [
      EthereumAddress.fromHex(payerHex),
    ]);
    return (res.first as List<dynamic>).cast<BigInt>();
  }

  Future<BigInt> getTotalInvoices() async {
    final res = await _readContract('totalInvoices', []);
    return res.first as BigInt;
  }

  Future<bool> isPaused() async {
    final res = await _readContract('paused', []);
    return res.first as bool;
  }

  Future<bool> isEmployee(String addressHex) async {
    final res = await _readContract('isEmployee', [
      EthereumAddress.fromHex(addressHex),
    ]);
    return res.first as bool;
  }

  Future<int> getUserTier(String addressHex) async {
    final res = await _readContract('getUserTier', [
      EthereumAddress.fromHex(addressHex),
    ]);
    return (res.first as BigInt).toInt();
  }

  // --- Write Functions ---

  // Deposit Native DC
  Future<String> depositETH(String privateKey, BigInt amountInWei) async {
    return _writeContract(
      privateKey,
      'depositETH',
      [],
      value: EtherAmount.fromBigInt(EtherUnit.wei, amountInWei),
    );
  }

  // Deposit ERC-20
  Future<String> depositToken(
    String privateKey,
    String tokenAddressHex,
    BigInt amount,
  ) async {
    return _writeContract(privateKey, 'depositToken', [
      EthereumAddress.fromHex(tokenAddressHex),
      amount,
    ]);
  }

  // ERC-20 Token Approve (direct to token contract)
  Future<String> approveToken(
    String privateKey,
    String tokenAddressHex,
    BigInt amount,
  ) async {
    final credentials = getCredentials(privateKey);
    final contract = DeployedContract(
      _erc20Contract.abi,
      EthereumAddress.fromHex(tokenAddressHex),
    );
    final function = contract.function('approve');
    final chainId = await _web3client.getChainId();

    return _web3client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: function,
        parameters: [EthereumAddress.fromHex(contractAddressHex), amount],
        maxGas: 100000,
      ),
      chainId: chainId.toInt(),
    );
  }

  // Withdraw Native DC
  Future<String> withdrawETH(String privateKey, BigInt amount) async {
    return _writeContract(privateKey, 'withdrawETH', [amount]);
  }

  // Withdraw Token
  Future<String> withdrawToken(
    String privateKey,
    String tokenAddressHex,
    BigInt amount,
  ) async {
    return _writeContract(privateKey, 'withdrawToken', [
      EthereumAddress.fromHex(tokenAddressHex),
      amount,
    ]);
  }

  // Create Invoice
  Future<String> createInvoice({
    required String privateKey,
    required String payer,
    required String token,
    required BigInt amount,
    required BigInt dueDate,
    required String description,
    required int paymentType, // 0 = PREPAID, 1 = POSTPAID
    required bool isRecurring,
    required BigInt recurringInterval,
    required BigInt maxCycles,
  }) async {
    return _writeContract(privateKey, 'createInvoice', [
      EthereumAddress.fromHex(payer),
      EthereumAddress.fromHex(token),
      amount,
      dueDate,
      description,
      paymentType,
      isRecurring,
      recurringInterval,
      maxCycles,
    ]);
  }

  // Pay Prepaid Invoice
  Future<String> payPrepaidInvoice(
    String privateKey,
    BigInt invoiceId,
    BigInt deadline,
  ) async {
    return _writeContract(privateKey, 'payPrepaidInvoice', [
      invoiceId,
      deadline,
    ]);
  }

  // Pay Postpaid Invoice
  Future<String> payPostpaidInvoice(
    String privateKey,
    BigInt invoiceId,
    BigInt deadline,
  ) async {
    return _writeContract(privateKey, 'payPostpaidInvoice', [
      invoiceId,
      deadline,
    ]);
  }

  // Mark Work Complete (Merchant)
  Future<String> markComplete(String privateKey, BigInt invoiceId) async {
    return _writeContract(privateKey, 'markComplete', [invoiceId]);
  }

  // Confirm Completion (Payer)
  Future<String> confirmCompletion(String privateKey, BigInt invoiceId) async {
    return _writeContract(privateKey, 'confirmCompletion', [invoiceId]);
  }

  // Raise Dispute (Payer)
  Future<String> raiseDispute(
    String privateKey,
    BigInt invoiceId,
    String reason,
  ) async {
    return _writeContract(privateKey, 'raiseDispute', [invoiceId, reason]);
  }

  // Claim Payment (Merchant)
  Future<String> claimPayment(String privateKey, BigInt invoiceId) async {
    return _writeContract(privateKey, 'claimPayment', [invoiceId]);
  }

  // Reclaim Funds (Payer)
  Future<String> reclaimFunds(String privateKey, BigInt invoiceId) async {
    return _writeContract(privateKey, 'reclaimFunds', [invoiceId]);
  }

  // Cancel Invoice (Merchant - PENDING only)
  Future<String> cancelInvoice(
    String privateKey,
    BigInt invoiceId,
    String reason,
  ) async {
    return _writeContract(privateKey, 'cancelInvoice', [invoiceId, reason]);
  }

  // Reject Invoice (Payer - PENDING only)
  Future<String> rejectInvoice(
    String privateKey,
    BigInt invoiceId,
    String reason,
  ) async {
    return _writeContract(privateKey, 'rejectInvoice', [invoiceId, reason]);
  }

  // Edit Invoice (Merchant - PENDING only)
  Future<String> editInvoice({
    required String privateKey,
    required BigInt invoiceId,
    required BigInt newAmount,
    required BigInt newDueDate,
    required String newDescription,
    required BigInt newRecurringInterval,
    required BigInt newMaxCycles,
  }) async {
    return _writeContract(privateKey, 'editInvoice', [
      invoiceId,
      newAmount,
      newDueDate,
      newDescription,
      newRecurringInterval,
      newMaxCycles,
    ]);
  }

  // Acknowledge Invoice (Payer)
  Future<String> acknowledgeInvoice(String privateKey, BigInt invoiceId) async {
    return _writeContract(privateKey, 'acknowledgeInvoice', [invoiceId]);
  }

  // --- Recurring Billing ---
  Future<String> approveRecurring({
    required String privateKey,
    required String merchant,
    required String token,
    required BigInt maxPerCycle,
    required BigInt totalLimit,
  }) async {
    return _writeContract(privateKey, 'approveRecurring', [
      EthereumAddress.fromHex(merchant),
      EthereumAddress.fromHex(token),
      maxPerCycle,
      totalLimit,
    ]);
  }

  Future<String> triggerRecurring(String privateKey, BigInt invoiceId) async {
    return _writeContract(privateKey, 'triggerRecurring', [invoiceId]);
  }

  Future<String> revokeRecurring({
    required String privateKey,
    required String merchant,
    required String token,
  }) async {
    return _writeContract(privateKey, 'revokeRecurring', [
      EthereumAddress.fromHex(merchant),
      EthereumAddress.fromHex(token),
    ]);
  }

  // --- P2P Transfer ---
  Future<String> transferToUser({
    required String privateKey,
    required String recipient,
    required String token,
    required BigInt amount,
    required bool isFamilyTransfer,
  }) async {
    return _writeContract(privateKey, 'transferToUser', [
      EthereumAddress.fromHex(recipient),
      EthereumAddress.fromHex(token),
      amount,
      isFamilyTransfer,
    ]);
  }

  Future<String> approveFamilySender({
    required String privateKey,
    required String sender,
    required bool approved,
  }) async {
    return _writeContract(privateKey, 'approveFamilySender', [
      EthereumAddress.fromHex(sender),
      approved,
    ]);
  }

  // --- Admin/Employee Commands ---
  Future<String> resolveDispute({
    required String privateKey,
    required BigInt invoiceId,
    required bool releaseToMerchant,
    required String reason,
  }) async {
    return _writeContract(privateKey, 'resolveDispute', [
      invoiceId,
      releaseToMerchant,
      reason,
    ]);
  }

  Future<String> challengeDispute({
    required String privateKey,
    required BigInt invoiceId,
    required String evidence,
  }) async {
    return _writeContract(privateKey, 'challengeDispute', [
      invoiceId,
      evidence,
    ]);
  }

  Future<String> finalizeResolution(String privateKey, BigInt invoiceId) async {
    return _writeContract(privateKey, 'finalizeResolution', [invoiceId]);
  }
}
