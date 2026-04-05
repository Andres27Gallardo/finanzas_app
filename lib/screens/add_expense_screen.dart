import 'package:flutter/material.dart';
import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final List<String> expenseCategories;
  final List<String> incomeCategories;
  final List<String> accounts;

  const AddExpenseScreen({
    super.key,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.accounts,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  String type = "gasto";
  String? selectedCategory;
  String? selectedAccount;

  DateTime selectedDateTime = DateTime.now();

  List<String> get currentCategories {
    return type == "ingreso"
        ? widget.incomeCategories
        : widget.expenseCategories;
  }

  @override
  void initState() {
    super.initState();
    selectedAccount = widget.accounts.first;
    selectedCategory = currentCategories.first;
  }

  void save() {
    final amount = double.tryParse(amountController.text);
    if (amount == null || selectedCategory == null) return;

    Navigator.pop(
      context,
      Expense(
        category: selectedCategory!,
        amount: amount,
        description: descriptionController.text,
        account: selectedAccount!,
        type: type,
        date: selectedDateTime,
      ),
    );
  }

  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
    );

    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year} | "
        "${d.hour.toString().padLeft(2, '0')}:"
        "${d.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Movimiento")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: type,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: "gasto", child: Text("Gasto")),
                DropdownMenuItem(value: "ingreso", child: Text("Ingreso")),
              ],
              onChanged: (v) {
                setState(() {
                  type = v!;
                  selectedCategory = currentCategories.first;
                });
              },
            ),

            const SizedBox(height: 10),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Monto"),
            ),

            const SizedBox(height: 10),

            DropdownButton<String>(
              value: selectedCategory,
              isExpanded: true,
              items: currentCategories
                  .toSet()
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => selectedCategory = v),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Descripción"),
            ),

            const SizedBox(height: 10),

            DropdownButton<String>(
              value: selectedAccount,
              isExpanded: true,
              items: widget.accounts
                  .toSet()
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => selectedAccount = v),
            ),

            const SizedBox(height: 15),

            // 📅 FECHA Y HORA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Fecha: ${formatDate(selectedDateTime)}"),
                ElevatedButton(
                  onPressed: pickDateTime,
                  child: const Text("Cambiar"),
                )
              ],
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