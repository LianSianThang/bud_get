import 'package:hive/hive.dart';

part 'debt.g.dart';

@HiveType(typeId: 1)
class Debt extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime dueDate;

  @HiveField(3)
  bool isPaid;

  // The constructor requires name, amount, and dueDate.
  // 'isPaid' is optional and defaults to 'false'.
  Debt({
    required this.name,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
  });
}