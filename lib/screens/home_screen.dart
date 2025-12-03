// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import '../models/setting.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Box<Transaction> transactionsBox = Hive.box<Transaction>('transactions');
    final Box<Setting> settingsBox = Hive.box<Setting>('settings');
    final currency = settingsBox.getAt(0)?.currency ?? 'MMK';

    // Total Income
    double totalIncome() {
      return transactionsBox.values
          .where((t) => t.type == 'income')
          .fold(0.0, (prev, t) => prev + t.amount);
    }

    // Total Expenses (only from transactions: expense, saving, debt)
    double totalExpenses() {
      return transactionsBox.values
          .where((t) => t.type == 'expense' || t.type == 'saving' || t.type == 'debt')
          .fold(0.0, (prev, t) => prev + t.amount);
    }

    // Map for pie chart: category => amount
    Map<String, double> getExpenseCategories() {
      final Map<String, double> dataMap = {};
      for (var t in transactionsBox.values.where(
              (t) => t.type == 'expense' || t.type == 'saving' || t.type == 'debt')) {
        dataMap[t.category] = (dataMap[t.category] ?? 0) + t.amount;
      }
      return dataMap;
    }

    return ValueListenableBuilder(
      valueListenable: transactionsBox.listenable(),
      builder: (context, _, __) {
        final income = totalIncome();
        final expense = totalExpenses();
        final expenseCategories = getExpenseCategories();

        // Define colors for each category
        final categoryColors = <String, Color>{
          'Saving': Colors.blue,
          'Debt': Colors.orange,
          // Other categories default to redAccent
        };

        return Scaffold(
          appBar: AppBar(title: const Text('Home')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Bar chart (Income vs Expenses)
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (income > expense ? income : expense) * 1.2,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text('Income');
                                  case 1:
                                    return const Text('Expenses');
                                  default:
                                    return const Text('');
                                }
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: income,
                                color: Colors.green,
                                width: 30,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: expense,
                                color: Colors.red,
                                width: 30,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Legend for bar chart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(width: 12, height: 12, color: Colors.green),
                          const SizedBox(width: 6),
                          Text('Income $currency${income.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Row(
                        children: [
                          Container(width: 12, height: 12, color: Colors.red),
                          const SizedBox(width: 6),
                          Text('Expenses $currency${expense.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Pie chart for expense categories
                  Text('Expenses Breakdown', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: expenseCategories.entries.map((entry) {
                          final category = entry.key;
                          final value = entry.value;
                          final color = categoryColors[category] ?? Colors.redAccent;

                          return PieChartSectionData(
                            color: color,
                            value: value,
                            title: '', // No title inside pie
                            radius: 60,
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Legend for pie chart
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: expenseCategories.entries.map((entry) {
                      final category = entry.key;
                      final value = entry.value;
                      final color = categoryColors[category] ?? Colors.redAccent;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 12, height: 12, color: color),
                          const SizedBox(width: 6),
                          Text('$category $currency${value.toStringAsFixed(2)}'),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
