// lib/screens/pay_debt_modal.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/debt.dart';
import '../models/setting.dart';
import '../models/transaction.dart';

class PayDebtModal extends StatefulWidget {
  final Debt debt;
  const PayDebtModal({super.key, required this.debt});

  @override
  _PayDebtModalState createState() => _PayDebtModalState();
}

class _PayDebtModalState extends State<PayDebtModal> {
  final amountController = TextEditingController();

  void _savePayment() {
    final paidAmount = double.tryParse(amountController.text) ?? 0.0;
    if (paidAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    if (paidAmount > widget.debt.amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paid amount exceeds debt')),
      );
      return;
    }

    // Reduce the debt
    widget.debt.amount -= paidAmount;
    if (widget.debt.amount <= 0) {
      widget.debt.amount = 0;
      widget.debt.isPaid = true;
    }
    widget.debt.save();

    // Record as a transaction (expense)
    final transactionsBox = Hive.box<Transaction>('transactions');
    final settingsBox = Hive.box<Setting>('settings');
    final currency = settingsBox.getAt(0)?.currency ?? 'MMK';

    final newTransaction = Transaction(
      type: 'expense',
      category: 'Debt Payment',
      description: 'Paid ${widget.debt.name}',
      amount: paidAmount,
      date: DateTime.now(),
    );
    transactionsBox.add(newTransaction);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box<Setting>('settings');
    final currency = settingsBox.getAt(0)?.currency ?? 'MMK';

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pay Off Debt',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Current Amount: $currency${widget.debt.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount Paid ($currency)',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _savePayment,
            child: const Text('Save Payment'),
          ),
        ],
      ),
    );
  }
}
