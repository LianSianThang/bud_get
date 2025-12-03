// lib/screens/debt_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/debt.dart';
import '../models/setting.dart';
import 'pay_debt_modal.dart';

class DebtScreen extends StatelessWidget {
  const DebtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box<Setting>('settings');
    final currency = settingsBox.getAt(0)?.currency ?? 'MMK';

    return Scaffold(
      appBar: AppBar(title: const Text('Debts')),
      body: ValueListenableBuilder<Box<Debt>>(
        valueListenable: Hive.box<Debt>('debts').listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('No debts recorded.'));
          }

          // Sort debts by due date
          final sortedDebts = box.values.toList()
            ..sort((a, b) {
              if (a.dueDate == null) return 1;
              if (b.dueDate == null) return -1;
              return a.dueDate.compareTo(b.dueDate);
            });

          return ListView.builder(
            itemCount: sortedDebts.length,
            itemBuilder: (context, index) {
              final debt = sortedDebts[index];
              final name = debt.name;
              final amount = debt.amount;
              final dueDate = debt.dueDate;
              final remainingDays = dueDate.difference(DateTime.now()).inDays;
              final isPaid = debt.isPaid || amount <= 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(
                    isPaid
                        ? 'Paid'
                        : remainingDays < 0
                        ? 'Overdue by ${-remainingDays} days'
                        : 'Due in $remainingDays days',
                    style: TextStyle(
                      color: isPaid
                          ? Colors.green
                          : (remainingDays < 0 ? Colors.red : Colors.orange),
                      fontWeight: isPaid ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isPaid ? 'Paid' : '$currency${amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isPaid ? Colors.green : null,
                          fontWeight: isPaid ? FontWeight.bold : null,
                        ),
                      ),
                      if (!isPaid)
                        TextButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => PayDebtModal(debt: debt),
                            );
                          },
                          child: const Text('Pay'),
                        ),
                      IconButton(
                        onPressed: () => debt.delete(),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
