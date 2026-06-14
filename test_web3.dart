import 'package:wallet/wallet.dart';

void main() {
  final amount = EtherAmount.fromInt(EtherUnit.ether, 1);
  final amountWei = EtherAmount.inWei(BigInt.from(100));
  print(amount.getInWei);
  print(amountWei.getInWei);
}
