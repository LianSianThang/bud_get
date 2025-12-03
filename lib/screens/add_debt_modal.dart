// lib/screens/add_debt_modal.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/debt.dart';
import '../models/setting.dart';

class AddDebtModal extends StatefulWidget {
  final Debt? debt; // Optional: edit existing debt
  const AddDebtModal({super.key, this.debt});

  @override
  _AddDebtModalState createState() => _AddDebtModalState();
}

class _AddDebtModalState extends State<AddDebtModal> {
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  DateTime? selectedDate;

  late String currency;

  @override
  void initState() {
    super.initState();
    final settingsBox = Hive.box<Setting>('settings');
    currency = settingsBox.getAt(0)?.currency ?? 'MMK';

    if (widget.debt != null) {
      nameController.text = widget.debt!.name;
      amountController.text = widget.debt!.amount.toString();
      selectedDate = widget.debt!.dueDate;
    }
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _saveDebt() {
    final name = nameController.text.trim();
    final amountText = amountController.text.trim();

    if (name.isEmpty || amountText.isEmpty || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    final debtBox = Hive.box<Debt>('debts');

    if (widget.debt == null) {
      // Add new debt
      final newDebt = Debt(
        name: name,
        amount: amount,
        dueDate: selectedDate!,
      );
      debtBox.add(newDebt);
    } else {
      // Update existing debt without adding duplicate transaction
      widget.debt!
        ..name = name
        ..amount = amount
        ..dueDate = selectedDate!
        ..save();
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
            widget.debt == null ? 'Add New Debt' : 'Edit Debt',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name / Creditor'),
          ),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount ($currency)',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedDate == null
                      ? 'No due date chosen'
                      : 'Due Date: ${selectedDate!.toLocal().toString().split(' ')[0]}',
                ),
              ),
              TextButton(
                onPressed: _pickDate,
                child: const Text('Pick Date'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveDebt,
            child: Text(widget.debt == null ? 'Add Debt' : 'Save Changes'),
          ),
        ],
      ),
    );
  }
}
