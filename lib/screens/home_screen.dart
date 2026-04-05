import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

  List<String> expenseCategories = ["Comida", "Transporte"];
  List<String> incomeCategories = ["Salario", "Negocio"];
  List<String> accounts = ["Efectivo", "Banco"];

  double get total {
    return expenses.fold(0, (sum, item) {
      return item.type == "ingreso"
          ? sum + item.amount
          : sum - item.amount;
    });
  }

  double get totalIngresos {
    return expenses
        .where((e) => e.type == "ingreso")
        .fold(0, (sum, e) => sum + e.amount);
  }

  double get totalGastos {
    return expenses
        .where((e) => e.type == "gasto")
        .fold(0, (sum, e) => sum + e.amount);
  }

  void addExpense(Expense e) {
    setState(() => expenses.add(e));
  }

  void addExpenseCategory(String c) {
    setState(() => expenseCategories.add(c));
  }

  void addIncomeCategory(String c) {
    setState(() => incomeCategories.add(c));
  }

  void addAccount(String c) {
    setState(() => accounts.add(c));
  }

  // 📅 FORMATO FECHA
  String formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year} | "
        "${d.hour.toString().padLeft(2, '0')}:"
        "${d.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final totalGeneral = totalIngresos + totalGastos;

    return Scaffold(
      appBar: AppBar(title: const Text("Mis Finanzas 💰")),
      body: Column(
        children: [
          const SizedBox(height: 20),

          const Text("Saldo total", style: TextStyle(fontSize: 18)),
          Text(
            "\$${total.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // 📊 GRÁFICA
          if (totalGeneral > 0)
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: totalIngresos,
                      title:
                          "${(totalIngresos / totalGeneral * 100).toStringAsFixed(1)}%",
                      color: Colors.green,
                    ),
                    PieChartSectionData(
                      value: totalGastos,
                      title:
                          "${(totalGastos / totalGeneral * 100).toStringAsFixed(1)}%",
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, i) {
                final e = expenses[i];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(e.category),

                    // 🔥 INFO COMPLETA
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.description),

                        // 🏦 CUENTA
                        Text(
                          "Cuenta: ${e.account}",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.blueGrey),
                        ),

                        // 📅 FECHA + HORA
                        Text(
                          formatDate(e.date),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),

                    trailing: Text(
                      "${e.type == "ingreso" ? "+" : "-"} \$${e.amount}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: e.type == "ingreso"
                            ? Colors.green
                            : Colors.red,
                      ),
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
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: FloatingActionButton(
              heroTag: "menu",
              backgroundColor: Colors.grey,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text("Categoría Gasto"),
                          onTap: () async {
                            Navigator.pop(context);
                            final r = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddCategoryScreen()),
                            );
                            if (r != null) addExpenseCategory(r);
                          },
                        ),
                        ListTile(
                          title: const Text("Categoría Ingreso"),
                          onTap: () async {
                            Navigator.pop(context);
                            final r = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddCategoryScreen()),
                            );
                            if (r != null) addIncomeCategory(r);
                          },
                        ),
                        ListTile(
                          title: const Text("Cuenta"),
                          onTap: () async {
                            Navigator.pop(context);
                            final r = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddCategoryScreen()),
                            );
                            if (r != null) addAccount(r);
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

          FloatingActionButton(
            heroTag: "add",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddExpenseScreen(
                    expenseCategories: expenseCategories,
                    incomeCategories: incomeCategories,
                    accounts: accounts,
                  ),
                ),
              );

              if (result != null) addExpense(result);
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}