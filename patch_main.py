import re

with open('lib/main.dart', 'r') as f:
    content = f.read()

# 1. Add _promptPrivateKey method
prompt_code = """
  Future<String?> _promptPrivateKey(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signature Required'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter Private Key to sign',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Sign'),
          ),
        ],
      ),
    );
  }
"""
if "_promptPrivateKey" not in content:
    content = content.replace('  Future<void> _refreshAll() async {', prompt_code + '\n  Future<void> _refreshAll() async {')

# 2. Connection Logic Updates
content = content.replace('final TextEditingController _privateKeyController = TextEditingController();', 'final TextEditingController _publicAddressController = TextEditingController();')
content = content.replace('_privateKeyController.text = savedPk;', '_publicAddressController.text = savedPk;')
content = content.replace("await _prefs.setString('private_key', _privateKeyController.text);", "await _prefs.setString('private_key', _publicAddressController.text);")
content = content.replace('_privateKeyController.text.isEmpty', '_publicAddressController.text.isEmpty')

old_connect = """      await _contractService.init(rpcUrl: _rpcController.text);
      final derivedAddress = await _contractService.getAddressFromPrivateKey(
        _privateKeyController.text,
      );

      setState(() {
        _userAddress = derivedAddress;
      });"""
new_connect = """      await _contractService.init(rpcUrl: _rpcController.text);
      setState(() {
        _userAddress = _publicAddressController.text;
      });"""
content = content.replace(old_connect, new_connect)

content = content.replace('hintText: "Enter your private key",', 'hintText: "Enter your public address (0x...)",')
content = content.replace('labelText: "Private Key",', 'labelText: "Public Wallet Address",')
content = content.replace('controller: _privateKeyController,', 'controller: _publicAddressController,')

# 3. Patching action methods to inject prompt
methods = ['_handleDeposit', '_handleWithdraw', '_handleP2pTransfer', '_handleCreateInvoice', '_handleInvoiceAction']

def insert_prompt(method_signature):
    global content
    regex = r"(" + re.escape(method_signature) + r"\s*\{)"
    replacement = r"\1\n    final privateKey = await _promptPrivateKey(context);\n    if (privateKey == null || privateKey.isEmpty) return;\n"
    content = re.sub(regex, replacement, content)

insert_prompt('Future<void> _handleDeposit() async')
insert_prompt('Future<void> _handleWithdraw() async')
insert_prompt('Future<void> _handleP2pTransfer() async')
insert_prompt('Future<void> _handleCreateInvoice() async')
# handleInvoiceAction takes args, so regex match:
content = re.sub(
    r'(Future<void> _handleInvoiceAction\(Invoice inv, String action\) async \{)',
    r'\1\n    final privateKey = await _promptPrivateKey(context);\n    if (privateKey == null || privateKey.isEmpty) return;\n',
    content
)

# Replace all remaining `_privateKeyController.text` with `privateKey` in those methods
# Since _privateKeyController.text is only used in connection (already replaced) and the action methods,
# we can just do a global replace for the remaining ones.
content = content.replace('_privateKeyController.text', 'privateKey')

with open('lib/main.dart', 'w') as f:
    f.write(content)
