// lib/screens/add_saving_goal_modal.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/saving_goal.dart';
import '../models/setting.dart';

class AddSavingGoalModal extends StatefulWidget {
  final SavingGoal? goal; // Optional existing goal
  const AddSavingGoalModal({super.key, this.goal});

  @override
  _AddSavingGoalModalState createState() => _AddSavingGoalModalState();
}

class _AddSavingGoalModalState extends State<AddSavingGoalModal> {
  final nameController = TextEditingController();
  final targetController = TextEditingController();

  late String currency;

  @override
  void initState() {
    super.initState();
    final settingsBox = Hive.box<Setting>('settings');
    currency = settingsBox.getAt(0)?.currency ?? 'MMK';

    if (widget.goal != null) {
      nameController.text = widget.goal!.name;
      targetController.text = widget.goal!.targetAmount.toString();
    }
  }

  void _saveGoal() {
    final name = nameController.text.trim();
    final target = double.tryParse(targetController.text.trim()) ?? 0.0;

    if (name.isEmpty || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid goal and target.")),
      );
      return;
    }

    final savingsBox = Hive.box<SavingGoal>('savings');

    if (widget.goal == null) {
      // Add new saving goal with 0 initial amount
      final newGoal = SavingGoal(
        name: name,
        targetAmount: target,
        currentAmount: 0.0,
      );
      savingsBox.add(newGoal);
    } else {
      // Update existing goal
      widget.goal!
        ..name = name
        ..targetAmount = target
        ..save();
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Padding(
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
                widget.goal == null ? 'Add New Goal' : 'Edit Goal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Goal Name'),
              ),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Target Amount ($currency)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveGoal,
                child: Text(widget.goal == null ? 'Add Goal' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
