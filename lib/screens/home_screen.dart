import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';
import 'add_category_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> expenses = [];

  List<String> incomeCategories = ["Salario"];
  List<String> expenseCategories = ["Comida"];
  List<String> accounts = ["Efectivo"];

  void addCategory(Map data) {
    setState(() {
      if (data["type"] == "ingreso") {
        incomeCategories.add(data["name"]);
      } else if (data["type"] == "egreso") {
        expenseCategories.add(data["name"]);
      } else if (data["type"] == "cuenta") {
        accounts.add(data["name"]);
      }
    });
  }

  double get totalIncome => expenses
      .where((e) => e.type == "ingreso")
      .fold(0, (sum, e) => sum + e.amount);

  double get totalExpense => expenses
      .where((e) => e.type == "egreso")
      .fold(0, (sum, e) => sum + e.amount);

  double get balance => totalIncome - totalExpense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Finanzas 💰")),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // 📊 GRAFICA
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: totalIncome,
                    color: Colors.green,
                    title: "Ingresos",
                  ),
                  PieChartSectionData(
                    value: totalExpense,
                    color: Colors.red,
                    title: "Egresos",
                  ),
                ],
              ),
            ),
          ),

          // 📦 RESUMEN
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _box("Ingresos", totalIncome, Colors.green),
              _box("Total", balance, Colors.grey),
              _box("Egresos", totalExpense, Colors.red),
            ],
          ),

          // 📋 LISTA
          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final e = expenses[index];

                String sign = "";
                Color color = Colors.black;

                if (e.type == "ingreso") {
                  sign = "+";
                  color = Colors.green;
                } else if (e.type == "egreso") {
                  sign = "-";
                  color = Colors.red;
                } else {
                  sign = "⇄";
                  color = Colors.blue;
                }

                return ListTile(
                  title: Text(e.category),

                  // 🔥 AQUÍ ESTÁ EL FIX REAL
                  subtitle: Text(
                    "${e.description}\n"
                    "Banco: ${e.account}"
                    "${e.toAccount != null ? " → ${e.toAccount}" : ""}\n"
                    "${e.date.day}/${e.date.month}/${e.date.year} "
                    "${e.date.hour}:${e.date.minute.toString().padLeft(2, '0')}",
                  ),

                  trailing: Text(
                    "$sign \$${e.amount}",
                    style: TextStyle(color: color),
                  ),
                );
              },
            ),
          )
        ],
      ),

      // 🔘 BOTONES
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ⚙️ MENU
          FloatingActionButton(
            heroTag: "menu",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddCategoryScreen(),
                ),
              );

              if (result != null) {
                addCategory(result);
              }
            },
            child: const Icon(Icons.menu),
          ),

          const SizedBox(height: 10),

          // 💰 INGRESO
          FloatingActionButton(
            heroTag: "income",
            backgroundColor: Colors.green,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddExpenseScreen(
                    type: "ingreso",
                    incomeCategories: incomeCategories,
                    expenseCategories: expenseCategories,
                    accounts: accounts,
                  ),
                ),
              );

              if (result != null) {
                setState(() => expenses.add(result));
              }
            },
            child: const Icon(Icons.arrow_downward),
          ),

          const SizedBox(height: 10),

          // 💸 EGRESO
          FloatingActionButton(
            heroTag: "expense",
            backgroundColor: Colors.red,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddExpenseScreen(
                    type: "egreso",
                    incomeCategories: incomeCategories,
                    expenseCategories: expenseCategories,
                    accounts: accounts,
                  ),
                ),
              );

              if (result != null) {
                setState(() => expenses.add(result));
              }
            },
            child: const Icon(Icons.arrow_upward),
          ),

          const SizedBox(height: 10),

          // 🔁 TRANSFERENCIA
          FloatingActionButton(
            heroTag: "transfer",
            backgroundColor: Colors.blue,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddExpenseScreen(
                    type: "transferencia",
                    incomeCategories: incomeCategories,
                    expenseCategories: expenseCategories,
                    accounts: accounts,
                  ),
                ),
              );

              if (result != null) {
                setState(() => expenses.add(result));
              }
            },
            child: const Icon(Icons.swap_horiz),
          ),
        ],
      ),
    );
  }

  Widget _box(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title),
          Text("\$${value.toStringAsFixed(2)}"),
        ],
      ),
    );
  }
}