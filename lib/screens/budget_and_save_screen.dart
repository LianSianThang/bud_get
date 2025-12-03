// lib/screens/budget_and_save_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';
import '../models/debt.dart';
import '../models/setting.dart';
import 'add_saving_goal_modal.dart';
import 'fund_modal.dart';

class BudgetAndSaveScreen extends StatefulWidget {
  const BudgetAndSaveScreen({super.key});

  @override
  _BudgetAndSaveScreenState createState() => _BudgetAndSaveScreenState();
}

class _BudgetAndSaveScreenState extends State<BudgetAndSaveScreen> {
  final budgetBox = Hive.box('budgets');
  final savingsBox = Hive.box<SavingGoal>('savings');
  final debtsBox = Hive.box<Debt>('debts');
  final transactionsBox = Hive.box<Transaction>('transactions');
  final settingsBox = Hive.box<Setting>('settings');

  double monthlyBudget = 0;
  double monthlyExpenses = 0;
  String currency = 'MMK';

  @override
  void initState() {
    super.initState();
    currency = settingsBox.getAt(0)?.currency ?? 'MMK';
    _loadData();
  }

  void _loadData() {
    final currentMonthKey = DateFormat('yyyy-MM').format(DateTime.now());
    monthlyBudget = budgetBox.get(currentMonthKey, defaultValue: 0.0);

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // 1️⃣ Expense transactions in current month
    double expenses = transactionsBox.values
        .where((t) =>
    t.date.isAfter(firstDayOfMonth) &&
        t.date.isBefore(lastDayOfMonth) &&
        t.type == 'expense' &&
        t.category != 'Savings') // Exclude savings transactions
        .fold(0.0, (sum, t) => sum + t.amount);

    // 2️⃣ Paid debts in current month
    double debtsPaid = debtsBox.values
        .where((d) =>
    d.dueDate.isAfter(firstDayOfMonth) &&
        d.dueDate.isBefore(lastDayOfMonth) &&
        d.isPaid)
        .fold(0.0, (sum, d) => sum + d.amount);

    // 3️⃣ Contributions to savings from transactions (avoid double counting)
    double savingsUsed = transactionsBox.values
        .where((t) =>
    t.category == 'Savings' &&
        t.type == 'expense' &&
        t.date.isAfter(firstDayOfMonth) &&
        t.date.isBefore(lastDayOfMonth))
        .fold(0.0, (sum, t) => sum + t.amount);

    // Total used budget for the month
    monthlyExpenses = expenses + debtsPaid + savingsUsed;
  }


  Future<void> _setBudget() async {
    final currentMonthKey = DateFormat('yyyy-MM').format(DateTime.now());
    final controller = TextEditingController(text: monthlyBudget.toString());

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Monthly Budget'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Budget Amount'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final newBudget = double.tryParse(controller.text) ?? 0.0;
                budgetBox.put(currentMonthKey, newBudget);
                setState(() => monthlyBudget = newBudget);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddGoalModal([SavingGoal? goal]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddSavingGoalModal(goal: goal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget & Savings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Monthly Budget Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Budget',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Budget: $currency${monthlyBudget.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text('Used: $currency${monthlyExpenses.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: monthlyExpenses > monthlyBudget
                                ? Colors.red
                                : Colors.green)),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: monthlyBudget > 0
                          ? monthlyExpenses / monthlyBudget
                          : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                          monthlyExpenses > monthlyBudget
                              ? Colors.red
                              : Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _setBudget, child: const Text('Set Budget')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Saving Goals Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Saving Goals', style: Theme.of(context).textTheme.titleLarge),
                ElevatedButton(
                  onPressed: () => _showAddGoalModal(),
                  child: const Text('Add Goal'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Saving Goals List
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: savingsBox.listenable(),
                builder: (context, Box<SavingGoal> box, _) {
                  if (box.isEmpty) {
                    return const Center(child: Text('No saving goals set.'));
                  }

                  return ListView.builder(
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      final goal = box.getAt(index)!;
                      double progress = goal.currentAmount / goal.targetAmount;
                      progress = progress.clamp(0.0, 1.0);

                      return Card(
                        child: ListTile(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => FundModal(goal: goal),
                          ),
                          title: Text(goal.name),
                          subtitle: LinearProgressIndicator(
                            value: progress,
                            color: Colors.green,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$currency${goal.currentAmount.toStringAsFixed(2)} / $currency${goal.targetAmount.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.right,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showAddGoalModal(goal),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => goal.delete(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
