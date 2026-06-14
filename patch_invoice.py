with open('lib/models/invoice.dart', 'r') as f:
    content = f.read()

replacement = """  factory Invoice.fromTuple(List<dynamic> tuple) {
    return Invoice(
      id: tuple[0] as BigInt,
      payer: tuple[1].toString(),
      merchant: tuple[2].toString(),
      token: tuple[3].toString(),
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
}
"""

content = content.split("  factory Invoice.fromTuple(List<dynamic> tuple) {")[0] + replacement

with open('lib/models/invoice.dart', 'w') as f:
    f.write(content)
