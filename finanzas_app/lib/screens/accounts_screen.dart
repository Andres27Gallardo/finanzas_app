import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/finance_provider.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanceProvider>();
    final fmt = NumberFormat.currency(locale: 'es', symbol: p.currency, decimalDigits: 2);
    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas', style: TextStyle(fontWeight: FontWeight.bold)), actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showAdd(context))]),
      body: p.accounts.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('🏦', style: TextStyle(fontSize: 64)), const SizedBox(height: 16), const Text('No tienes cuentas', style: TextStyle(color: Colors.grey)), const SizedBox(height: 16), ElevatedButton.icon(onPressed: () => _showAdd(context), icon: const Icon(Icons.add), label: const Text('Agregar cuenta'))]))
        : ListView(padding: const EdgeInsets.all(16), children: [
            Card(color: const Color(0xFF6C63FF), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Balance general', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(fmt.format(p.totalBalance), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
              const Text('Solo cuentas con ✓ activo', style: TextStyle(color: Colors.white60, fontSize: 11)),
            ]))),
            const SizedBox(height: 12),
            ...p.accounts.map((acc) => Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(children: [
              Container(width: 46, height: 46, decoration: BoxDecoration(color: Color(acc.colorValue).withOpacity(0.2), shape: BoxShape.circle), child: Center(child: Text(acc.icon, style: const TextStyle(fontSize: 22)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(fmt.format(acc.balance), style: TextStyle(fontWeight: FontWeight.bold, color: acc.balance >= 0 ? Colors.green : Colors.red)),
              ])),
              Column(children: [
                const Text('Balance', style: TextStyle(fontSize: 9, color: Colors.grey)),
                Switch(value: acc.includeInBalance, onChanged: (_) => context.read<FinanceProvider>().toggleAccountInBalance(acc.id), activeColor: const Color(0xFF6C63FF), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ]),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22), onPressed: () async {
                final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                  title: const Text('Eliminar cuenta'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [Text('¿Eliminar "${acc.name}"?'), const SizedBox(height: 8), const Text('Al eliminar esta cuenta serán eliminados todos los datos vinculados (transacciones, deudas y objetivos).', style: TextStyle(color: Colors.red, fontSize: 12))]),
                  actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red)))],
                ));
                if (ok == true && context.mounted) context.read<FinanceProvider>().deleteAccount(acc.id);
              }),
            ])))),
          ]),
    );
  }
  void _showAdd(BuildContext context) => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _AddAccountSheet());
}

class _AddAccountSheet extends StatefulWidget {
  const _AddAccountSheet();
  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}
class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  final _iconCtrl = TextEditingController();
  Color _color = const Color(0xFF6C63FF);
  bool _includeInBalance = true;
  @override
  void dispose() { _nameCtrl.dispose(); _balanceCtrl.dispose(); _iconCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Nueva Cuenta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.account_balance_wallet_outlined)), textCapitalization: TextCapitalization.words),
        const SizedBox(height: 12),
        TextField(controller: _balanceCtrl, decoration: const InputDecoration(labelText: 'Saldo inicial', prefixIcon: Icon(Icons.attach_money)), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 12),
        TextField(controller: _iconCtrl, decoration: const InputDecoration(labelText: 'Emoji (opcional)', hintText: '🏦 💳 💵 🏧 📱', prefixIcon: Icon(Icons.emoji_emotions_outlined)), style: const TextStyle(fontSize: 22), maxLength: 4),
        Row(children: [
          const Text('Color:', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(width: 12),
          GestureDetector(onTap: () => _pickColor(context), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: _color, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 2)))),
          const SizedBox(width: 10),
          TextButton(onPressed: () => _pickColor(context), child: const Text('Personalizar')),
        ]),
        SwitchListTile(title: const Text('Incluir en balance general', style: TextStyle(fontSize: 14)), subtitle: const Text('Suma al total del inicio', style: TextStyle(fontSize: 11)), value: _includeInBalance, onChanged: (v) => setState(() => _includeInBalance = v), activeColor: const Color(0xFF6C63FF), contentPadding: EdgeInsets.zero),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {
          if (_nameCtrl.text.trim().isEmpty) return;
          context.read<FinanceProvider>().addAccount(name: _nameCtrl.text.trim(), initialBalance: double.tryParse(_balanceCtrl.text) ?? 0, colorValue: _color.value, icon: _iconCtrl.text.trim().isEmpty ? '🏦' : _iconCtrl.text.trim(), includeInBalance: _includeInBalance);
          Navigator.pop(context);
        }, child: const Text('Guardar cuenta'))),
      ]),
    );
  }
  void _pickColor(BuildContext context) => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Elige un color'), content: SingleChildScrollView(child: ColorPicker(pickerColor: _color, onColorChanged: (c) => setState(() => _color = c), pickerAreaHeightPercent: 0.7, enableAlpha: false, labelTypes: const [])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Listo'))]));
}
