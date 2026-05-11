import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/finance_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  await Hive.initFlutter();
  await Hive.openBox('transactions');
  await Hive.openBox('accounts');
  await Hive.openBox('categories');
  await Hive.openBox('user_data');
  await Hive.openBox('settings');
  await Hive.openBox('goals');
  await Hive.openBox('debts');
  // ✅ Nueva caja para pagos frecuentes
  await Hive.openBox('recurring_payments');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinanceProvider()..init(),
      child: Consumer<FinanceProvider>(
        builder: (_, p, __) => MaterialApp(
          title: 'My Money IA',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: p.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
