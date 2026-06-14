import re

content = """import 'dart:convert';
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
"""

with open('lib/services/contract_service.dart', 'r') as f:
    orig = f.read()

# We take the rest of the functions from orig
rest = orig.split("  Future<List<BigInt>> getMerchantInvoices(String merchantHex) async {")[1]

full = content + "\n  Future<List<BigInt>> getMerchantInvoices(String merchantHex) async {\n" + rest

with open('lib/services/contract_service.dart', 'w') as f:
    f.write(full)
