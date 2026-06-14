import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final bool isMerchant;
  final Function(String) onAction;

  const InvoiceCard({
    Key? key,
    required this.invoice,
    required this.isMerchant,
    required this.onAction,
  }) : super(key: key);

  String _getStatusString(int status) {
    switch (status) {
      case 0:
        return "PENDING";
      case 1:
        return "ACTIVE";
      case 2:
        return "PAID (ESCROW)";
      case 3:
        return "AWAITING CONFIRMATION";
      case 4:
        return "COMPLETED";
      case 5:
        return "CANCELLED";
      case 6:
        return "DISPUTED";
      case 7:
        return "CHALLENGE PENDING";
      default:
        return "UNKNOWN";
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
      case 1:
        return AppTheme.primaryColor;
      case 2:
      case 3:
        return AppTheme.warningColor;
      case 4:
        return AppTheme.successColor;
      case 5:
      case 6:
      case 7:
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(invoice.status);
    final statusString = _getStatusString(invoice.status);
    final amountDecimals = AppConstants.getDecimals(AppConstants.getSymbol(invoice.token));
    final displayAmount = (invoice.amount / BigInt.from(10).pow(amountDecimals)).toStringAsFixed(2);
    final symbol = AppConstants.getSymbol(invoice.token);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Invoice #${invoice.id}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusString,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),
            _infoRow("Description:", invoice.description),
            _infoRow("Amount:", "$displayAmount $symbol"),
            _infoRow("Type:", invoice.paymentType == 0 ? "PREPAID (Escrow)" : "POSTPAID"),
            if (invoice.isRecurring)
              _infoRow("Recurring:", "${invoice.completedCycles} / ${invoice.maxCycles} Cycles"),
            
            // Render action buttons based on status
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    List<Widget> buttons = [];

    if (!isMerchant && invoice.status == 0) {
      buttons.add(_actionButton("Pay Invoice", "pay", AppTheme.successColor));
      buttons.add(_actionButton("Reject", "reject", AppTheme.errorColor));
    }
    if (isMerchant && invoice.status == 0) {
      buttons.add(_actionButton("Cancel", "cancel", AppTheme.errorColor));
    }
    if (isMerchant && invoice.status == 2) {
      buttons.add(_actionButton("Mark Complete", "mark_complete", AppTheme.primaryColor));
    }
    if (!isMerchant && invoice.status == 3) {
      buttons.add(_actionButton("Confirm Completion", "confirm", AppTheme.successColor));
      buttons.add(_actionButton("Raise Dispute", "dispute", AppTheme.warningColor));
    }
    if (isMerchant && invoice.status == 3) {
      buttons.add(_actionButton("Claim Timeout", "claim", AppTheme.primaryColor));
    }
    if (!isMerchant && invoice.status == 2) {
      buttons.add(_actionButton("Reclaim Funds", "reclaim", AppTheme.warningColor));
    }
    if (isMerchant && invoice.isRecurring && (invoice.status == 1 || invoice.status == 0)) {
      buttons.add(_actionButton("Trigger Cycle", "trigger", AppTheme.primaryColor));
    }
    if (!isMerchant && invoice.status == 7) {
      buttons.add(_actionButton("Challenge Ruling", "challenge", AppTheme.errorColor));
    }
    if (invoice.status == 7) {
      buttons.add(_actionButton("Finalize Resolution", "finalize", AppTheme.primaryColor));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons,
    );
  }

  Widget _actionButton(String text, String action, Color color) {
    return ElevatedButton(
      onPressed: () => onAction(action),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
      ),
      child: Text(text),
    );
  }
}
