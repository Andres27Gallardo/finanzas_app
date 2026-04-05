import 'package:flutter/material.dart';
import '../models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  final List<String> incomeCategories;
  final List<String> expenseCategories;
  final List<String> accounts;

  const AddTransactionScreen({
    super.key,
    required this.incomeCategories,
    required this.expenseCategories,
    required this.accounts,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool isIncome = false;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedCategory;
  String? selectedAccount;

  DateTime selectedDate = DateTime.now();

  void save() {
    final double? amount = double.tryParse(amountController.text);

    if (amount == null ||
        selectedCategory == null ||
        selectedAccount == null) return;

    final tx = TransactionModel(
      amount: amount,
      category: selectedCategory!,
      description: descriptionController.text,
      account: selectedAccount!,
      date: selectedDate,
      isIncome: isIncome,
    );

    Navigator.pop(context, tx);
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        isIncome ? widget.incomeCategories : widget.expenseCategories;

    return Scaffold(
      appBar: AppBar(title: const Text("Nuevo movimiento")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ChoiceChip(
                  label: const Text("Egreso"),
                  selected: !isIncome,
                  onSelected: (_) => setState(() => isIncome = false),
                ),
                ChoiceChip(
                  label: const Text("Ingreso"),
                  selected: isIncome,
                  onSelected: (_) => setState(() => isIncome = true),
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
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => selectedCategory = v),
              decoration: const InputDecoration(
                labelText: "Categoría",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Descripción",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: selectedAccount,
              items: widget.accounts
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => selectedAccount = v),
              decoration: const InputDecoration(
                labelText: "Cuenta",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: save,
              child: const Text("Guardar"),
            )
          ],
        ),
      ),
    );
  }
}