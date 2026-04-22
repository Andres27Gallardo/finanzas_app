import 'package:flutter/material.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final TextEditingController controller = TextEditingController();
  String type = "egreso";

  void save() {
    if (controller.text.isEmpty) return;

    Navigator.pop(context, {
      "name": controller.text,
      "type": type,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agregar")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField(
              value: type,
              items: const [
                DropdownMenuItem(value: "egreso", child: Text("Categoría Egreso")),
                DropdownMenuItem(value: "ingreso", child: Text("Categoría Ingreso")),
                DropdownMenuItem(value: "cuenta", child: Text("Cuenta (Banco)")),
              ],
              onChanged: (value) {
                setState(() {
                  type = value!;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Tipo",
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Nombre",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: save, child: const Text("Guardar"))
          ],
        ),
      ),
    );
  }
}