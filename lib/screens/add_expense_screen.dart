import 'package:flutter/material.dart';
import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  void saveExpense() {
  final double? amount = double.tryParse(amountController.text);
  final String category = categoryController.text;

  if (amount == null || category.isEmpty) {
    return;
  }

  final expense = Expense(
    category: category,
    amount: amount,
  );

  Navigator.pop(context, expense);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agregar gasto"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Monto",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: categoryController,
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