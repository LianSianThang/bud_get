// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/setting.dart';
import '../models/transaction.dart';
import '../models/debt.dart';
import '../models/saving_goal.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box<Setting> settingsBox;
  late Setting setting;

  final List<String> currencies = ['MMK', '\$', '€', '¥'];

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box<Setting>('settings');

    if (settingsBox.isEmpty) {
      setting = Setting(); // default values
      settingsBox.add(setting);
    } else {
      setting = settingsBox.getAt(0)!;
    }
  }

  void _updateTheme(String theme) {
    setState(() {
      setting.theme = theme;
      setting.save();
    });
  }

  void _updateCurrency(String currency) {
    setState(() {
      setting.currency = currency;
      setting.save();
    });
  }

  void _exportPDF() async {
    final pdf = pw.Document();

    final transactionsBox = Hive.box<Transaction>('transactions');
    final debtsBox = Hive.box<Debt>('debts');
    final savingsBox = Hive.box<SavingGoal>('savings');

    final totalIncome = transactionsBox.values
        .where((t) => t.type == 'income')
        .fold<double>(0, (prev, t) => prev + t.amount);

    final totalExpenses = transactionsBox.values
        .where((t) => t.type != 'income')
        .fold<double>(0, (prev, t) => prev + t.amount) +
        debtsBox.values.where((d) => d.isPaid).fold<double>(0, (prev, d) => prev + d.amount) +
        savingsBox.values.fold<double>(0, (prev, s) => prev + s.currentAmount);

    final totalDebtPaid = debtsBox.values.where((d) => d.isPaid).fold<double>(0, (prev, d) => prev + d.amount);
    final totalSaved = savingsBox.values.fold<double>(0, (prev, s) => prev + s.currentAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, text: 'Zenith 2.0 Report'),
          pw.SizedBox(height: 10),

          // Transactions Table
          pw.Text('Transactions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
          pw.SizedBox(height: 5),
          pw.Table.fromTextArray(
            headers: ['Type', 'Category', 'Amount', 'Date', 'Description'],
            data: [
              ...transactionsBox.values.map((t) => [
                t.type,
                t.category,
                '${setting.currency}${t.amount.toStringAsFixed(2)}',
                DateFormat('yyyy-MM-dd').format(t.date),
                t.description.isNotEmpty ? t.description : '-',
              ]),
              ['Total', '', '${setting.currency}${totalIncome.toStringAsFixed(2)}', '', '']
            ],
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
            cellPadding: pw.EdgeInsets.all(4),
          ),
          pw.SizedBox(height: 20),

          // Debts Table
          pw.Text('Debts', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
          pw.SizedBox(height: 5),
          pw.Table.fromTextArray(
            headers: ['Status', 'Name', 'Amount', 'Due Date'],
            data: [
              ...debtsBox.values.map((d) => [
                d.isPaid ? 'Paid' : 'Unpaid',
                d.name,
                '${setting.currency}${d.amount.toStringAsFixed(2)}',
                DateFormat('yyyy-MM-dd').format(d.dueDate),
              ]),
              ['Total Paid', '', '${setting.currency}${totalDebtPaid.toStringAsFixed(2)}', '']
            ],
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
            cellPadding: pw.EdgeInsets.all(4),
          ),
          pw.SizedBox(height: 20),

          // Savings Table
          pw.Text('Savings', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
          pw.SizedBox(height: 5),
          pw.Table.fromTextArray(
            headers: ['Name', 'Saved', 'Target'],
            data: [
              ...savingsBox.values.map((s) => [
                s.name,
                '${setting.currency}${s.currentAmount.toStringAsFixed(2)}',
                '${setting.currency}${s.targetAmount.toStringAsFixed(2)}',
              ]),
              ['Total', '${setting.currency}${totalSaved.toStringAsFixed(2)}', '']
            ],
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
            cellPadding: pw.EdgeInsets.all(4),
          ),

          pw.SizedBox(height: 20),
          pw.Text('Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
          pw.SizedBox(height: 5),
          pw.Text('Total Income: ${setting.currency}${totalIncome.toStringAsFixed(2)}'),
          pw.Text('Total Expenses: ${setting.currency}${totalExpenses.toStringAsFixed(2)}'),
          pw.Text('Total Debt Paid: ${setting.currency}${totalDebtPaid.toStringAsFixed(2)}'),
          pw.Text('Total Saved: ${setting.currency}${totalSaved.toStringAsFixed(2)}'),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme toggle
            Text('Theme', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Light'),
                  selected: setting.theme == 'light',
                  onSelected: (_) => _updateTheme('light'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Dark'),
                  selected: setting.theme == 'dark',
                  onSelected: (_) => _updateTheme('dark'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Currency selector
            Text('Currency', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: setting.currency,
              items: currencies
                  .map((c) => DropdownMenuItem(
                value: c,
                child: Text(c),
              ))
                  .toList(),
              onChanged: (value) {
                if (value != null) _updateCurrency(value);
              },
            ),
            const SizedBox(height: 24),

            // Export PDF button
            ElevatedButton.icon(
              onPressed: _exportPDF,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export as PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
