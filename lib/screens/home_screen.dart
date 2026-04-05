import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';
import 'add_category_screen.dart';
import 'add_account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TransactionModel> transactions = [];

  List<String> expenseCategories = ["Comida", "Transporte"];
  List<String> incomeCategories = ["Salario", "Regalo"];
  List<String> accounts = ["Efectivo", "Banco"];

  double get total {
    return transactions.fold(0, (sum, t) {
      return t.isIncome ? sum + t.amount : sum - t.amount;
    });
  }

  void addTransaction(TransactionModel tx) {
    setState(() {
      transactions.add(tx);
    });
  }

  void addCategory(String name, bool isIncome) {
    setState(() {
      if (isIncome) {
        incomeCategories.add(name);
      } else {
        expenseCategories.add(name);
      }
    });
  }

  void addAccount(String acc) {
    setState(() {
      accounts.add(acc);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Finanzas 💰")),
      body: Column(
        children: [
          const SizedBox(height: 20),

          Text(
            "\$${total.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 32),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, i) {
                final t = transactions[i];

                return ListTile(
                  title: Text("${t.category} (${t.account})"),
                  subtitle: Text(t.description),
                  trailing: Text(
                    "${t.isIncome ? '+' : '-'} \$${t.amount}",
                    style: TextStyle(
                        color:
                            t.isIncome ? Colors.green : Colors.red),
                  ),
                );
              },
            ),
          )
        ],
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "menu",
            backgroundColor: Colors.grey,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text("Agregar categoría egreso"),
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AddCategoryScreen()),
                          );
                          if (result != null) addCategory(result, false);
                        },
                      ),
                      ListTile(
                        title: const Text("Agregar categoría ingreso"),
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AddCategoryScreen()),
                          );
                          if (result != null) addCategory(result, true);
                        },
                      ),
                      ListTile(
                        title: const Text("Agregar cuenta"),
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AddAccountScreen()),
                          );
                          if (result != null) addAccount(result);
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: const Icon(Icons.menu),
          ),

          const SizedBox(height: 10),

          FloatingActionButton(
            heroTag: "add",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionScreen(
                    incomeCategories: incomeCategories,
                    expenseCategories: expenseCategories,
                    accounts: accounts,
                  ),
                ),
              );

              if (result != null) addTransaction(result);
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}