import 'package:flutter/material.dart';
import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final List<String> incomeCategories;
  final List<String> expenseCategories;
  final List<String> accounts;
  final String type;

  const AddExpenseScreen({
    super.key,
    required this.incomeCategories,
    required this.expenseCategories,
    required this.accounts,
    required this.type,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedCategory;
  String? selectedAccount;
  String? selectedToAccount;

  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final categories = widget.type == "ingreso"
        ? widget.incomeCategories
        : widget.expenseCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == "transferencia"
              ? "Transferencia"
              : "Agregar ${widget.type}",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 💰 MONTO
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Monto",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // 📂 CATEGORIA (NO PARA TRANSFERENCIA)
            if (widget.type != "transferencia")
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
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

            if (widget.type != "transferencia")
              const SizedBox(height: 15),

            // 📝 DESCRIPCIÓN
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Descripción",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // 🏦 CUENTA ORIGEN
            DropdownButtonFormField<String>(
              value: selectedAccount,
              items: widget.accounts
                  .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedAccount = value;
                });
              },
              decoration: const InputDecoration(
                labelText: "Cuenta",
                border: OutlineInputBorder(),
              ),
            ),

            // 🔁 CUENTA DESTINO SOLO EN TRANSFERENCIA
            if (widget.type == "transferencia") ...[
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedToAccount,
                items: widget.accounts
                    .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(a),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedToAccount = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Cuenta destino",
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 15),

            // 📅 FECHA
            ListTile(
              title: Text(
                  "Fecha: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} ${selectedDate.hour}:${selectedDate.minute.toString().padLeft(2, '0')}"),
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

            const SizedBox(height: 20),

            // 💾 GUARDAR
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);

                if (amount == null || selectedAccount == null) return;

                if (widget.type != "transferencia" &&
                    selectedCategory == null) return;

                if (widget.type == "transferencia" &&
                    selectedToAccount == null) return;

                Navigator.pop(
                  context,
                  Expense(
                    type: widget.type,
                    category: selectedCategory ?? "Transferencia",
                    amount: amount,
                    description: descriptionController.text,
                    account: selectedAccount!,
                    toAccount: selectedToAccount,
                    date: selectedDate,
                  ),
                );
              },
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }
}