class Invoice {
  final BigInt id;
  final String payer;
  final String merchant;
  final String token;
  final BigInt amount;
  final BigInt dueDate;
  final String description;
  final int paymentType; // 0 = PREPAID, 1 = POSTPAID
  final int status; // 0=PENDING, 1=ACTIVE, 2=PAID, 3=AWAITING_CONF, 4=COMPLETED, 5=CANCELLED, 6=DISPUTED, 7=CHALLENGE
  final bool isRecurring;
  final BigInt recurringInterval;
  final BigInt maxCycles;
  final BigInt completedCycles;
  final BigInt nextDueDate;
  final BigInt createdAt;
  final bool payerAcknowledged;

  Invoice({
    required this.id,
    required this.payer,
    required this.merchant,
    required this.token,
    required this.amount,
    required this.dueDate,
    required this.description,
    required this.paymentType,
    required this.status,
    required this.isRecurring,
    required this.recurringInterval,
    required this.maxCycles,
    required this.completedCycles,
    required this.nextDueDate,
    required this.createdAt,
    required this.payerAcknowledged,
  });

  factory Invoice.fromTuple(List<dynamic> tuple) {
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
