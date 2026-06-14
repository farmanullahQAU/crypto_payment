import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BalanceCard extends StatelessWidget {
  final String title;
  final String balance;
  final String ledgerBalance;
  final IconData icon;
  final Color accentColor;

  const BalanceCard({
    Key? key,
    required this.title,
    required this.balance,
    required this.ledgerBalance,
    required this.icon,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: accentColor, size: 28),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Text("Wallet", style: TextStyle(color: Colors.white54, fontSize: 12)),
          Text(
            balance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text("Platform", style: TextStyle(color: Colors.white54, fontSize: 12)),
          Text(
            ledgerBalance,
            style: TextStyle(
              color: AppTheme.successColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
