// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/setting.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Box<Transaction> transactionsBox = Hive.box<Transaction>('transactions');
    final Box<Setting> settingsBox = Hive.box<Setting>('settings');
    final currency = settingsBox.getAt(0)?.currency ?? 'MMK';

    // Sort transactions by date descending
    List<Transaction> getHistory() {
      final transactions = transactionsBox.values.toList();
      transactions.sort((a, b) => b.date.compareTo(a.date));
      return transactions;
    }

    String formatDateLabel(DateTime date) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final target = DateTime(date.year, date.month, date.day);

      if (target == today) return "Today";
      if (target == yesterday) return "Yesterday";
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    }

    return ValueListenableBuilder(
      valueListenable: transactionsBox.listenable(),
      builder: (context, _, __) {
        final history = getHistory();

        if (history.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('History')),
            body: const Center(child: Text('No history yet!')),
          );
        }

        // Group by date label
        final Map<String, List<Transaction>> grouped = {};
        for (var tx in history) {
          final label = formatDateLabel(tx.date);
          grouped.putIfAbsent(label, () => []).add(tx);
        }

        return Scaffold(
          appBar: AppBar(title: const Text('History')),
          body: ListView(
            children: grouped.entries.map((entry) {
              final label = entry.key;
              final items = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      label,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...items.map((tx) {
                    final isIncome = tx.type == 'income';
                    final trailingText =
                        '${isIncome ? '+' : '-'} $currency${tx.amount.toStringAsFixed(2)}';
                    final trailingColor = isIncome ? Colors.green : Colors.red;
                    final leadingIcon = Icon(isIncome ? Icons.add : Icons.remove, color: trailingColor);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: leadingIcon,
                        title: Text(tx.category),
                        subtitle: tx.description.isNotEmpty ? Text(tx.description) : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              trailingText,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: trailingColor,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: const Text('Are you sure you want to delete this transaction?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          tx.delete();
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
