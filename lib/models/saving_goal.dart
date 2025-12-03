// lib/models/saving_goal.dart
import 'package:hive/hive.dart';

part 'saving_goal.g.dart';

@HiveType(typeId: 2) // Note: The typeId must be unique
class SavingGoal extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double targetAmount;

  @HiveField(2)
  double currentAmount;

  SavingGoal({
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
  });
}