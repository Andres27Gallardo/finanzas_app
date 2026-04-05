import 'package:flutter/material.dart';
import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final List<String> categories;

  const AddExpenseScreen({super.key, required this.categories});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController amountController = TextEditingController();
  String? selectedCategory;

  bool isIncome = false;

  void saveExpense() {
    final double? amount = double.tryParse(amountController.text);

    if (amount == null || selectedCategory == null) return;

    final expense = Expense(
      category: selectedCategory!,
      amount: amount,
      isIncome: isIncome,
    );

    Navigator.pop(context, expense);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Movimiento"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔘 Selector ingreso/gasto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ChoiceChip(
                  label: const Text("Gasto"),
                  selected: !isIncome,
                  onSelected: (_) {
                    setState(() {
                      isIncome = false;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text("Ingreso"),
                  selected: isIncome,
                  onSelected: (_) {
                    setState(() {
                      isIncome = true;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Monto",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: widget.categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
              decoration: const InputDecoration(
                labelText: "Categoría",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveExpense,
              child: const Text("Guardar"),
            )
          ],
        ),
      ),
    );
  }
}