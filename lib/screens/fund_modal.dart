// lib/screens/fund_modal.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';
import '../models/setting.dart';

class FundModal extends StatefulWidget {
  final SavingGoal goal;
  const FundModal({super.key, required this.goal});

  @override
  _FundModalState createState() => _FundModalState();
}

class _FundModalState extends State<FundModal> {
  final amountController = TextEditingController();
  bool isAdding = true;

  void _saveFunds() {
    final amount = double.tryParse(amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final transactionsBox = Hive.box<Transaction>('transactions');
    final settingsBox = Hive.box<Setting>('settings');
    final currency = settingsBox.getAt(0)?.currency ?? 'MMK';

    if (isAdding) {
      widget.goal.currentAmount += amount;
      transactionsBox.add(Transaction(
        category: "Savings",
        amount: amount,
        date: DateTime.now(),
        type: "expense",
        description: "Added $currency${amount.toStringAsFixed(2)} to ${widget.goal.name}",
      ));
    } else {
      widget.goal.currentAmount -= amount;
      transactionsBox.add(Transaction(
        category: "Savings",
        amount: amount,
        date: DateTime.now(),
        type: "income",
        description: "Removed $currency${amount.toStringAsFixed(2)} from ${widget.goal.name}",
      ));
    }

    widget.goal.save();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${isAdding ? 'Add' : 'Remove'} Funds',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Adding Funds'),
              Switch(
                value: isAdding,
                onChanged: (value) {
                  setState(() {
                    isAdding = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveFunds,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
