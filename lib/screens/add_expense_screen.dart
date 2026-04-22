import 'package:flutter/material.dart';
import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final List<String> incomeCategories;
  final List<String> expenseCategories;
  final List<String> accounts;

  const AddExpenseScreen({
    super.key,
    required this.incomeCategories,
    required this.expenseCategories,
    required this.accounts,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String type = "egreso";
  String? selectedCategory;
  String? fromAccount;
  String? toAccount;

  DateTime selectedDate = DateTime.now();

  void saveExpense() {
    final double? amount = double.tryParse(amountController.text);

    if (amount == null) return;

    if (type == "transferencia") {
      if (fromAccount == null || toAccount == null) return;

      final expense = Expense(
        amount: amount,
        category: "Transferencia",
        description: descriptionController.text,
        type: "transferencia",
        account: fromAccount!,
        toAccount: toAccount!,
        date: selectedDate,
      );

      Navigator.pop(context, expense);
      return;
    }

    if (selectedCategory == null || fromAccount == null) return;

    final expense = Expense(
      amount: amount,
      category: selectedCategory!,
      description: descriptionController.text,
      type: type,
      account: fromAccount!,
      date: selectedDate,
    );

    Navigator.pop(context, expense);
  }

  @override
  Widget build(BuildContext context) {
    final categories = type == "ingreso"
        ? widget.incomeCategories
        : widget.expenseCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Agregar movimiento"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: type,
              items: const [
                DropdownMenuItem(value: "ingreso", child: Text("Ingreso")),
                DropdownMenuItem(value: "egreso", child: Text("Egreso")),
                DropdownMenuItem(value: "transferencia", child: Text("Transferencia")),
              ],
              onChanged: (value) {
                setState(() {
                  type = value!;
                  selectedCategory = null;
                });
              },
              decoration: const InputDecoration(labelText: "Tipo"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Monto"),
            ),

            const SizedBox(height: 10),

            if (type != "transferencia")
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories
                    .toSet()
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
                decoration: const InputDecoration(labelText: "Categoría"),
              ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: fromAccount,
              items: widget.accounts
                  .map((acc) => DropdownMenuItem(
                        value: acc,
                        child: Text(acc),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  fromAccount = value;
                });
              },
              decoration: const InputDecoration(labelText: "Cuenta"),
            ),

            const SizedBox(height: 10),

            if (type == "transferencia")
              DropdownButtonFormField<String>(
                value: toAccount,
                items: widget.accounts
                    .map((acc) => DropdownMenuItem(
                          value: acc,
                          child: Text(acc),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    toAccount = value;
                  });
                },
                decoration: const InputDecoration(labelText: "A qué cuenta"),
              ),

            const SizedBox(height: 10),

            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Descripción"),
            ),

            const SizedBox(height: 10),

            ListTile(
              title: Text(
                "Fecha: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );

                if (date != null) {
                  setState(() {
                    selectedDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      selectedDate.hour,
                      selectedDate.minute,
                    );
                  });
                }
              },
            ),

            ListTile(
              title: Text(
                "Hora: ${selectedDate.hour}:${selectedDate.minute}",
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(selectedDate),
                );

                if (time != null) {
                  setState(() {
                    selectedDate = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveExpense,
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }
}