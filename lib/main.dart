import 'package:flutter/material.dart';
import 'screens/main_layout.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CryptoPaymentApp());
}

class CryptoPaymentApp extends StatelessWidget {
  const CryptoPaymentApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Payment',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainLayout(),
    );
  }
}
