import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});
  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Exportar a Excel', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📊', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text('Exportar movimientos', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Elige el rango de fechas y comparte el archivo Excel.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        _DatePicker(label: 'Desde', date: _from, onPick: (d) => setState(() => _from = d)),
        const SizedBox(height: 16),
        _DatePicker(label: 'Hasta', date: _to, onPick: (d) => setState(() => _to = d)),
        const SizedBox(height: 24),
        Consumer<FinanceProvider>(builder: (_, p, __) {
          final count = p.getFilteredTransactions(from: _from, to: _to).length;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Text('📋', style: TextStyle(fontSize: 24)), const SizedBox(width: 12),
              Expanded(child: Text('$count movimiento(s) encontrado(s)', style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
          );
        }),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _loading ? null : _export,
          icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.share),
          label: Text(_loading ? 'Generando...' : 'Generar y Compartir Excel'),
        )),
        const SizedBox(height: 16),
        const Text('El archivo se abrirá para compartir por WhatsApp, Drive, email, etc.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ])),
    );
  }

  Future<void> _export() async {
    setState(() => _loading = true);
    final p = context.read<FinanceProvider>();
    final txs = p.getFilteredTransactions(from: _from, to: _to);

    if (txs.isEmpty) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay movimientos en este rango'), backgroundColor: Colors.orange));
      return;
    }

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Movimientos'];

      // Encabezados
      final headers = ['Fecha','Tipo','Descripción','Categoría','Cuenta','Monto','Moneda'];
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
      }

      final fmt = DateFormat('dd/MM/yyyy');
      for (var i = 0; i < txs.length; i++) {
        final t = txs[i];
        final cat = p.getCategoryById(t.categoryId);
        final acc = p.getAccountById(t.accountId);
        String tipo = t.type == TransactionType.income ? 'Ingreso' : t.type == TransactionType.expense ? 'Gasto' : 'Transferencia';
        final row = [fmt.format(t.date), tipo, t.description, cat?.name ?? '', acc?.name ?? '', t.amount, p.currency];
        for (var j = 0; j < row.length; j++) {
          final v = row[j];
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1)).value = v is double ? DoubleCellValue(v) : TextCellValue(v.toString());
        }
      }

      // Hoja resumen
      final sum = excel['Resumen'];
      final ingresos = txs.where((t) => t.type == TransactionType.income).fold<double>(0, (s, t) => s + t.amount);
      final gastos = txs.where((t) => t.type == TransactionType.expense).fold<double>(0, (s, t) => s + t.amount);
      [['Período','${fmt.format(_from)} al ${fmt.format(_to)}'],['Total movimientos','${txs.length}'],['Ingresos','$ingresos'],['Gastos','$gastos'],['Balance','${ingresos - gastos}'],['Moneda',p.currency]].asMap().forEach((i, row) {
        sum.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).value = TextCellValue(row[0]);
        sum.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i)).value = TextCellValue(row[1]);
      });

      // Guardar en temp y compartir
      final dir = await getTemporaryDirectory();
      final fileName = 'finanzas_${fmt.format(_from).replaceAll('/','_')}_${fmt.format(_to).replaceAll('/','_')}.xlsx';
      final path = '${dir.path}/$fileName';
      final bytes = excel.save();
      if (bytes != null) {
        File(path)..createSync(recursive: true)..writeAsBytesSync(bytes);
        // ✅ Compartir — funciona en Android y iOS
        await Share.shareXFiles([XFile(path)], subject: 'Mis movimientos financieros', text: 'Aquí están mis movimientos de ${fmt.format(_from)} al ${fmt.format(_to)}');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    setState(() => _loading = false);
  }
}

class _DatePicker extends StatelessWidget {
  final String label; final DateTime date; final Function(DateTime) onPick;
  const _DatePicker({required this.label, required this.date, required this.onPick});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () async { final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now()); if (d != null) onPick(d); },
    borderRadius: BorderRadius.circular(12),
    child: InputDecorator(decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.calendar_today_outlined)), child: Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(fontSize: 15))),
  );
}
