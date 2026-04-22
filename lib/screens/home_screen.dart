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

  List<String> incomeCategories = ["Salario", "Negocio"];
  List<String> expenseCategories = ["Comida", "Transporte"];

  List<String> accounts = ["Banco", "Efectivo"];

  double get totalIngresos =>
      expenses.where((e) => e.type == "ingreso").fold(0, (sum, e) => sum + e.amount);

  double get totalEgresos =>
      expenses.where((e) => e.type == "egreso").fold(0, (sum, e) => sum + e.amount);

  double get total => totalIngresos - totalEgresos;

  void addExpense(Expense expense) {
    setState(() {
      expenses.add(expense);
    });
  }

  void addCategory(String category, String type) {
    setState(() {
      if (type == "ingreso") {
        incomeCategories.add(category);
      } else {
        expenseCategories.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Finanzas 💰")),
      body: Column(
        children: [
          const SizedBox(height: 20),

          /// GRAFICA
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: totalIngresos,
                    color: Colors.green,
                    title: totalIngresos == 0
                        ? ""
                        : "${(totalIngresos / (totalIngresos + totalEgresos) * 100).toStringAsFixed(1)}%",
                  ),
                  PieChartSectionData(
                    value: totalEgresos,
                    color: Colors.red,
                    title: totalEgresos == 0
                        ? ""
                        : "${(totalEgresos / (totalIngresos + totalEgresos) * 100).toStringAsFixed(1)}%",
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// CUADROS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _box("Ingresos", totalIngresos, Colors.green),
              _box("Total", total, Colors.grey),
              _box("Egresos", totalEgresos, Colors.red),
            ],
          ),

          const SizedBox(height: 10),

          /// LISTA
          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final e = expenses[index];

                return ListTile(
                  title: Text(e.category),
                  subtitle: Text(e.description),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${e.type == "ingreso" ? "+" : "-"} \$${e.amount}",
                        style: TextStyle(
                          color: e.type == "ingreso"
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      Text(
                        "${e.date.day}/${e.date.month}/${e.date.year} | ${e.date.hour}:${e.date.minute}",
                        style: const TextStyle(fontSize: 10),
                      ),
                      Text(
                        e.type == "transferencia"
                            ? "${e.account} → ${e.toAccount}"
                            : e.account,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: FloatingActionButton(
              backgroundColor: Colors.grey,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text("Categoría ingreso"),
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddCategoryScreen(),
                            ),
                          );
                          if (result != null) {
                            addCategory(result, "ingreso");
                          }
                        },
                      ),
                      ListTile(
                        title: const Text("Categoría egreso"),
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddCategoryScreen(),
                            ),
                          );
                          if (result != null) {
                            addCategory(result, "egreso");
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
              child: const Icon(Icons.menu),
            ),
          ),

          FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddExpenseScreen(
                    incomeCategories: incomeCategories,
                    expenseCategories: expenseCategories,
                    accounts: accounts,
                  ),
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

  Widget _box(String title, double value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title),
          Text(
            "\$${value.toStringAsFixed(2)}",
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}