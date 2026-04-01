import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> expenses = [];

  double get total {
    return expenses.fold(0, (sum, item) => sum - item.amount);
  }

  void addExpense(Expense expense) {
    setState(() {
      expenses.add(expense);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Finanzas 💰"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          const Text(
            "Saldo total",
            style: TextStyle(fontSize: 18),
          ),

          Text(
            "\$${total.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return ListTile(
                  title: Text(expense.category),
                  trailing: Text("- \$${expense.amount}"),
                );
              },
            ),
          )
        ],
      ),

      // 👇 AQUÍ ESTÁ LA MAGIA (2 BOTONES)
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🔘 Botón izquierdo (menú)
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: FloatingActionButton(
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
                          leading: const Icon(Icons.category),
                          title: const Text("Agregar categoría"),
                          onTap: () {
                            Navigator.pop(context);
                            print("Agregar categoría");
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.account_balance),
                          title: const Text("Agregar cuenta"),
                          onTap: () {
                            Navigator.pop(context);
                            print("Agregar cuenta");
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Icon(Icons.menu),
            ),
          ),

          // ➕ Botón derecho (agregar gasto)
          FloatingActionButton(
            heroTag: "add",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddExpenseScreen(),
                ),
              );

              if (result != null) {
                addExpense(result);
              }
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}