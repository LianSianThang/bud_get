import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  String category;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String type; // 'income' or 'expense'

  @HiveField(4)
  String description;

  // The constructor requires all fields to be initialized.
  Transaction({
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    required this.description,
  });
}