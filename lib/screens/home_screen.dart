import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';
import 'add_category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> expenses = [];

  List<String> categories = [
    "Comida",
    "Transporte",
    "Entretenimiento"
  ];

  double get total {
    return expenses.fold(0, (sum, item) {
      return item.isIncome ? sum + item.amount : sum - item.amount;
    });
  }

  void addExpense(Expense expense) {
    setState(() {
      expenses.add(expense);
    });
  }

  void addCategory(String category) {
    setState(() {
      categories.add(category);
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
                  trailing: Text(
                    "${expense.isIncome ? '+' : '-'} \$${expense.amount}",
                    style: TextStyle(
                      color: expense.isIncome
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),

      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🔘 BOTÓN MENÚ
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
                          onTap: () async {
                            Navigator.pop(context);

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AddCategoryScreen(),
                              ),
                            );

                            if (result != null) {
                              addCategory(result);
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.account_balance),
                          title: const Text("Agregar cuenta"),
                          onTap: () {
                            Navigator.pop(context);
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

          // ➕ BOTÓN AGREGAR
          FloatingActionButton(
            heroTag: "add",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddExpenseScreen(categories: categories),
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