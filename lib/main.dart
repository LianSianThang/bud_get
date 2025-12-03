import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/transaction.dart';
import 'models/debt.dart';
import 'models/saving_goal.dart';
import 'models/setting.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register adapters (only once)
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(DebtAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(SavingGoalAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(SettingAdapter());

  // Open boxes
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox('budgets');
  await Hive.openBox<Debt>('debts');
  await Hive.openBox<SavingGoal>('savings');
  await Hive.openBox<Setting>('settings');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box<Setting>('settings');

    // Ensure default setting exists
    if (settingsBox.isEmpty) {
      settingsBox.add(Setting());
    }

    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(),
      builder: (context, Box<Setting> box, _) {
        final setting = box.getAt(0)!;
        final isDark = setting.theme == 'dark';

        return MaterialApp(
          title: 'Zenith 2.0',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              foregroundColor: isDark ? Colors.white : Colors.black,
              elevation: 2,
            ),
            bottomAppBarTheme: BottomAppBarThemeData(
              color: isDark ? Colors.grey[900] : Colors.white,
              elevation: 4,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          home: const MainScreen(),
        );
      },
    );
  }
}
