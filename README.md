# Crypto Payment Platform - Smart Contract Integration

This document outlines how the Flutter application integrates and interacts with the Ethereum/EVM-compatible smart contracts using the `web3dart` package.

## 1. Prerequisites & Setup
The project uses the `web3dart` package to communicate with the blockchain and `http` for RPC requests. 
All core interactions are encapsulated within the `ContractService` (`lib/services/contract_service.dart`).

**Key Configuration:**
- **Default RPC URL:** `https://rpc.testnet.dailycrypto.net`
- **Main Contract Address:** `0xC93ABa2273C47e0f8298FD49Cd193B8B045cD631`

## 2. Connecting the ABI
To interact with a deployed contract, we need its Application Binary Interface (ABI). 

1. **Storage:** The compiled ABI JSON files are stored in the `assets/` directory:
   - `assets/CryptoPaymentPlatform.json` (Main logic)
   - `assets/erc20_abi.json` (Standard ERC-20 token interface)
2. **Initialization:** When the app starts, `ContractService.init()` is called. It loads the ABI files asynchronously using Flutter's `rootBundle`.
3. **Deployment Binding:** The parsed ABI and the contract's hexadecimal address are passed to `DeployedContract`, creating an object we can call functions on.

```dart
// Example of ABI loading internally
final abiString = await rootBundle.loadString('assets/CryptoPaymentPlatform.json');
final abiJson = json.decode(abiString);
_platformContract = DeployedContract(
  ContractAbi.fromJson(json.encode(abiJson['abi']), 'CryptoPaymentPlatform'),
  EthereumAddress.fromHex(contractAddressHex),
);
```

## 3. Interacting with the Smart Contract

### Reading Data (View Functions)
View functions do not modify the blockchain state and cost no gas. We use `_web3client.call()` to execute them.

**How it works:**
1. Fetch the specific `ContractFunction` from the `DeployedContract`.
2. Call `_web3client.call(...)` passing the contract, the function, and any required parameters.

*Example:*
```dart
Future<BigInt> getTotalInvoices() async {
  final function = _platformContract.function('totalInvoices');
  final response = await _web3client.call(
    contract: _platformContract,
    function: function,
    params: [],
  );
  return response.first as BigInt;
}
```

### Writing Data (Signing and Sending Transactions)
State-changing functions require signing a transaction with a private key and paying gas.

**How it works:**
1. **Credentials:** The user's hexadecimal private key is converted into an `EthPrivateKey` object.
2. **Transaction Construction:** We use `Transaction.callContract(...)`, providing the function to execute, the parameters, and optionally any native value (e.g., Ether/DC) to send.
3. **Signing & Broadcasting:** `_web3client.sendTransaction(...)` automatically signs the transaction using the provided credentials and the network's `chainId`, then broadcasts it to the network.

*Example:*
```dart
Future<String> createInvoice(String privateKey, String payer, BigInt amount /* ... */) async {
  // 1. Get credentials from private key
  final credentials = EthPrivateKey.fromHex(privateKey);
  
  // 2. Fetch function signature
  final function = _platformContract.function('createInvoice');
  final chainId = await _web3client.getChainId();

  // 3. Sign and send
  return await _web3client.sendTransaction(
    credentials,
    Transaction.callContract(
      contract: _platformContract,
      function: function,
      parameters: [EthereumAddress.fromHex(payer), amount /* ... */],
      maxGas: 3000000,
    ),
    chainId: chainId.toInt(),
  );
}
```

## Summary
1. **Connect:** Load ABI from `assets/` -> Create `DeployedContract`.
2. **Read:** Use `_web3client.call()` for gas-free state queries.
3. **Write:** Convert private key to `EthPrivateKey` -> Use `_web3client.sendTransaction()` to sign and broadcast state changes.
