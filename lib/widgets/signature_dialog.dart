import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SignatureDialog extends StatefulWidget {
  const SignatureDialog({Key? key}) : super(key: key);

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SignatureDialog(),
    );
  }
}

class _SignatureDialogState extends State<SignatureDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.security, color: AppTheme.primaryColor),
          SizedBox(width: 10),
          Text('Signature Required', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Please enter your private key to sign this transaction. Your key is not saved anywhere.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: '0x...',
              labelText: 'Private Key',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            final key = _controller.text.trim();
            if (key.isNotEmpty) {
              Navigator.pop(context, key);
            }
          },
          child: const Text('Sign Transaction'),
        ),
      ],
    );
  }
}
