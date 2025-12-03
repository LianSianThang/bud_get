// lib/screens/add_transaction_modal.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/setting.dart';

class AddTransactionModal extends StatefulWidget {
  final Transaction? transaction; // Optional for editing
  const AddTransactionModal({super.key, this.transaction});

  @override
  _AddTransactionModalState createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'expense';
  String _category = 'Food';
  double _amount = 0.0;
  String _description = '';

  final List<String> _expenseCategories = ['Food', 'Shopping', 'Health', 'Gift', 'Other'];
  final List<String> _incomeCategories = ['Salary', 'Gift', 'Pocket Money', 'Fund', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _type = widget.transaction!.type;
      _category = widget.transaction!.category;
      _amount = widget.transaction!.amount;
      _description = widget.transaction!.description;
    } else {
      _category = _expenseCategories[0];
    }
  }

  void _submitTransaction() {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final box = Hive.box<Transaction>('transactions');

    if (widget.transaction == null) {
      box.add(Transaction(
        description: _description,
        amount: _amount,
        date: DateTime.now(),
        type: _type,
        category: _category,
      ));
    } else {
      widget.transaction!
        ..description = _description
        ..amount = _amount
        ..type = _type
        ..category = _category
        ..save();
    }

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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.transaction == null ? 'Add New Transaction' : 'Edit Transaction',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(labelText: 'Description (Optional)'),
              onSaved: (value) => _description = value ?? '',
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _amount != 0 ? _amount.toString() : '',
              decoration: InputDecoration(labelText: 'Amount ($currency)'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              onSaved: (value) => _amount = double.parse(value!),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'expense', child: Text('Expense')),
                DropdownMenuItem(value: 'income', child: Text('Income')),
              ],
              onChanged: (value) {
                setState(() {
                  _type = value!;
                  _category = (_type == 'expense' ? _expenseCategories[0] : _incomeCategories[0]);
                });
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: (_type == 'expense' ? _expenseCategories : _incomeCategories)
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitTransaction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.transaction == null ? 'Add Transaction' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
