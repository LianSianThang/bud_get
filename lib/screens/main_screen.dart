// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'budget_and_save_screen.dart';
import 'debt_screen.dart';
import 'history_screen.dart';
import 'add_transaction_modal.dart';
import 'add_debt_modal.dart';
import 'add_saving_goal_modal.dart';
import 'setting_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = <Widget>[
    const HomeScreen(),
    const BudgetAndSaveScreen(),
    const DebtScreen(),
    const HistoryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddOptionsModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.purple),
              title: const Text('Add Transaction'),
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const AddTransactionModal(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.purple),
              title: const Text('Add Debt'),
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const AddDebtModal(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.purple),
              title: const Text('Add Saving Goal'),
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const AddSavingGoalModal(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // removes default left padding
        title: _selectedIndex == 0 ? const Text('Zenith 2.0') : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(child: _screens[_selectedIndex]),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptionsModal,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        elevation: 8,
        color: theme.bottomAppBarTheme.color ?? theme.colorScheme.surface,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildNavIcon(Icons.home, 0, theme),
                  _buildNavIcon(Icons.account_balance_wallet, 1, theme),
                ],
              ),
              Row(
                children: [
                  _buildNavIcon(Icons.credit_card, 2, theme),
                  _buildNavIcon(Icons.history, 3, theme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index, ThemeData theme) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
            color: theme.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          )
              : null,
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 28,
            color: isSelected ? theme.primaryColor : theme.iconTheme.color,
          ),
        ),
      ),
    );
  }
}
