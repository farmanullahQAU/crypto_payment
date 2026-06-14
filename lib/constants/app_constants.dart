/// Application Constants
class AppConstants {
  // Network
  static const String defaultRpcUrl = "https://rpc.testnet.dailycrypto.net";

  // Contract Addresses
  static const String platformAddress =
      "0xC93ABa2273C47e0f8298FD49Cd193B8B045cD631";
  static const String usdtAddress =
      "0x25D10a10514298bEcbE491c1Ae727FaF2f852538";
  static const String usdcAddress =
      "0xAc894b21891EcD48B89eC85b74032b42421c67F8";
  static const String nativeAddress =
      "0x0000000000000000000000000000000000000000";

  // Shared Preferences Keys
  static const String prefsRpcUrl = "rpc_url";
  static const String prefsPrivateKey = "private_key";

  // Supported Tokens
  static const List<Map<String, dynamic>> supportedTokens = [
    {"symbol": "Native DC", "address": nativeAddress, "decimals": 18},
    {"symbol": "USDT", "address": usdtAddress, "decimals": 6},
    {"symbol": "USDC", "address": usdcAddress, "decimals": 6},
  ];

  // Helper method
  static int getDecimals(String symbol) {
    return supportedTokens.firstWhere((t) => t['symbol'] == symbol)['decimals']
        as int;
  }

  static String getAddress(String symbol) {
    return supportedTokens.firstWhere((t) => t['symbol'] == symbol)['address']
        as String;
  }

  static String getSymbol(String address) {
    try {
      return supportedTokens.firstWhere((t) => t['address'].toString().toLowerCase() == address.toLowerCase())['symbol'] as String;
    } catch (_) {
      return "Unknown";
    }
  }
}
