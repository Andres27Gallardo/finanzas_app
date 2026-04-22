import 'package:flutter/material.dart';
import '../models/expense.dart';

class AddTransferScreen extends StatefulWidget {
  final List<String> accounts;

  const AddTransferScreen({super.key, required this.accounts});

  @override
  State<AddTransferScreen> createState() => _AddTransferScreenState();
}

class _AddTransferScreenState extends State<AddTransferScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? fromAccount;
  String? toAccount;

  DateTime selectedDate = DateTime.now();

  void saveTransfer() {
    final amount = double.tryParse(amountController.text);

    if (amount == null || fromAccount == null || toAccount == null) return;

    final transfer = Expense(
      type: "transferencia",
      category: "Transferencia",
      amount: amount,
      description: descriptionController.text,
      account: fromAccount!,
      toAccount: toAccount!,
      date: selectedDate,
    );

    Navigator.pop(context, transfer);
  }

  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDate),
    );

    if (time == null) return;

    setState(() {
      selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transferencia")),
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

            DropdownButtonFormField<String>(
              value: fromAccount,
              hint: const Text("Cuenta origen"),
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
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: toAccount,
              hint: const Text("Cuenta destino"),
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${selectedDate.day}/${selectedDate.month}/${selectedDate.year} | ${selectedDate.hour}:${selectedDate.minute.toString().padLeft(2, '0')}",
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: pickDateTime,
                ),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveTransfer,
              child: const Text("Guardar"),
            )
          ],
        ),
      ),
    );
  }
}