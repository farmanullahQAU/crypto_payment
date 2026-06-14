import re

with open('lib/main.dart', 'r') as f:
    content = f.read()

def insert_prompt(method_signature):
    global content
    regex = r"(" + re.escape(method_signature) + r"[^{]*\{)"
    replacement = r"\1\n    final privateKey = await _promptPrivateKey(context);\n    if (privateKey == null || privateKey.isEmpty) return;\n"
    content = re.sub(regex, replacement, content)

insert_prompt('Future<void> _handleApprove(String tokenHex) async')
insert_prompt('Future<void> _handleP2PTransfer() async')
insert_prompt('Future<void> _handleApproveFamilySender() async')

with open('lib/main.dart', 'w') as f:
    f.write(content)
