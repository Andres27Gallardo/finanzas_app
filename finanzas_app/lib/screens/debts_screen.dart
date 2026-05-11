import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/debt.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanceProvider>();
    final fmt = NumberFormat.currency(locale: 'es', symbol: p.currency, decimalDigits: 2);
    final active = p.debts.where((d) => !d.isCompleted).toList();
    final done = p.debts.where((d) => d.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deudas', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showAdd(context))],
      ),
      body: p.debts.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🤝', style: TextStyle(fontSize: 64)), const SizedBox(height: 16),
            const Text('No hay deudas registradas', style: TextStyle(color: Colors.grey, fontSize: 16)), const SizedBox(height: 8),
            const Text('Registra préstamos y sigue quién\nte debe o a quién le debes', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: () => _showAdd(context), icon: const Icon(Icons.add), label: const Text('Registrar deuda')),
          ]))
        : ListView(padding: const EdgeInsets.all(16), children: [
            if (active.isNotEmpty) ...[
              Text('Activas (${active.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
              const SizedBox(height: 8),
              ...active.map((d) => _DebtCard(debt: d, fmt: fmt)),
              const SizedBox(height: 20),
            ],
            if (done.isNotEmpty) ...[
              Text('Completadas (${done.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              const SizedBox(height: 8),
              ...done.map((d) => _DebtCard(debt: d, fmt: fmt)),
            ],
          ]),
    );
  }

  void _showAdd(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _AddDebtSheet());
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt; final NumberFormat fmt;
  const _DebtCard({required this.debt, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final p = context.read<FinanceProvider>();
    final acc = p.getAccountById(debt.accountId);
    final retAcc = p.getAccountById(debt.returnAccountId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(debt.isLent ? '💸' : '💰', style: const TextStyle(fontSize: 28)), const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(debt.personName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(debt.isLent ? 'Le presté dinero' : 'Me prestó dinero', style: TextStyle(fontSize: 12, color: debt.isLent ? Colors.orange : Colors.green)),
          ])),
          if (debt.isCompleted) const Icon(Icons.check_circle, color: Colors.green),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () async {
            final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Eliminar deuda'), content: Text('¿Eliminar la deuda con "${debt.personName}"?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red)))]));
            if (ok == true && context.mounted) context.read<FinanceProvider>().deleteDebt(debt.id);
          }),
        ]),
        const SizedBox(height: 12),
        // Progreso
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(fmt.format(debt.paidAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          Text('de ${fmt.format(debt.totalAmount)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: debt.progress, minHeight: 8, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(debt.isCompleted ? Colors.green : Colors.orange))),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${(debt.progress * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(debt.isCompleted ? '✅ Completada' : 'Faltan ${fmt.format(debt.remaining)}', style: TextStyle(fontSize: 12, color: debt.isCompleted ? Colors.green : Colors.grey)),
        ]),
        if (acc != null || retAcc != null) ...[
          const SizedBox(height: 8),
          Text('📤 Cuenta origen: ${acc?.icon ?? ''} ${acc?.name ?? 'N/A'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text('📥 Cuenta retorno: ${retAcc?.icon ?? ''} ${retAcc?.name ?? 'N/A'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
        if (debt.dueDate != null) ...[
          const SizedBox(height: 4),
          Text('📅 Fecha límite: ${DateFormat('dd/MM/yyyy').format(debt.dueDate!)}', style: TextStyle(fontSize: 11, color: debt.dueDate!.isBefore(DateTime.now()) ? Colors.red : Colors.grey)),
        ],
        if (debt.returnFrequencyDays != null) ...[
          const SizedBox(height: 4),
          Text('🔄 Se devuelve cada ${debt.returnFrequencyDays} días', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
        if (debt.notes.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('📝 ${debt.notes}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
        if (!debt.isCompleted) ...[
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => _showAddPayment(context, debt, fmt),
            icon: const Icon(Icons.add, size: 16), label: const Text('Registrar abono'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange), padding: const EdgeInsets.symmetric(vertical: 10)),
          )),
        ],
      ])),
    );
  }

  void _showAddPayment(BuildContext context, Debt d, NumberFormat fmt) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Abono para "${d.personName}"'),
      content: TextField(controller: ctrl, decoration: InputDecoration(labelText: 'Monto del abono', prefixText: '${context.read<FinanceProvider>().currency} '), keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () { final a = double.tryParse(ctrl.text) ?? 0; if (a > 0) context.read<FinanceProvider>().addDebtPayment(d.id, a); Navigator.pop(context); }, child: const Text('Registrar')),
      ],
    ));
  }
}

class _AddDebtSheet extends StatefulWidget {
  const _AddDebtSheet();
  @override
  State<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<_AddDebtSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _accountId, _returnAccountId;
  DateTime? _dueDate;
  int? _freqDays;
  bool _isLent = true;

  @override
  void dispose() { _nameCtrl.dispose(); _amountCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanceProvider>();
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Registrar Deuda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        // Tipo: presté / me prestaron
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => setState(() => _isLent = true), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _isLent ? Colors.orange : Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.5))), child: Column(children: [const Text('💸', style: TextStyle(fontSize: 20)), Text('Yo presté', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _isLent ? Colors.white : Colors.orange))])))),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(onTap: () => setState(() => _isLent = false), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: !_isLent ? Colors.green : Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.5))), child: Column(children: [const Text('💰', style: TextStyle(fontSize: 20)), Text('Me prestaron', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: !_isLent ? Colors.white : Colors.green))])))),
        ]),
        const SizedBox(height: 16),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre de la persona', prefixIcon: Icon(Icons.person_outline)), textCapitalization: TextCapitalization.words),
        const SizedBox(height: 12),
        TextField(controller: _amountCtrl, decoration: InputDecoration(labelText: 'Monto total', prefixText: '${p.currency} ', prefixIcon: const Icon(Icons.attach_money)), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _accountId, decoration: const InputDecoration(labelText: 'Cuenta de donde salió', prefixIcon: Icon(Icons.account_balance_wallet_outlined)), items: p.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.icon} ${a.name}'))).toList(), onChanged: (v) => setState(() => _accountId = v)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _returnAccountId, decoration: const InputDecoration(labelText: 'Cuenta donde recibirás el retorno', prefixIcon: Icon(Icons.arrow_downward)), items: p.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.icon} ${a.name}'))).toList(), onChanged: (v) => setState(() => _returnAccountId = v)),
        const SizedBox(height: 12),
        // Frecuencia de devolución
        DropdownButtonFormField<int?>(value: _freqDays, decoration: const InputDecoration(labelText: 'Frecuencia de devolución (opcional)', prefixIcon: Icon(Icons.repeat)), items: const [
          DropdownMenuItem(value: null, child: Text('Sin frecuencia')),
          DropdownMenuItem(value: 7, child: Text('Cada semana (7 días)')),
          DropdownMenuItem(value: 14, child: Text('Cada 2 semanas (14 días)')),
          DropdownMenuItem(value: 21, child: Text('Cada 3 semanas (21 días)')),
          DropdownMenuItem(value: 30, child: Text('Cada mes (30 días)')),
        ], onChanged: (v) => setState(() => _freqDays = v)),
        const SizedBox(height: 12),
        // Fecha límite
        InkWell(
          onTap: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 5))); if (d != null) setState(() => _dueDate = d); },
          child: InputDecorator(decoration: const InputDecoration(labelText: 'Fecha límite (opcional)', prefixIcon: Icon(Icons.calendar_today_outlined)), child: Text(_dueDate != null ? DateFormat('dd/MM/yyyy').format(_dueDate!) : 'Sin fecha límite', style: TextStyle(color: _dueDate != null ? null : Colors.grey))),
        ),
        const SizedBox(height: 12),
        TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notas (opcional)', prefixIcon: Icon(Icons.notes_outlined)), textCapitalization: TextCapitalization.sentences),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final amount = double.tryParse(_amountCtrl.text) ?? 0;
            if (name.isEmpty || amount <= 0 || _accountId == null || _returnAccountId == null) return;
            context.read<FinanceProvider>().addDebt(personName: name, totalAmount: amount, accountId: _accountId!, returnAccountId: _returnAccountId!, startDate: DateTime.now(), dueDate: _dueDate, returnFrequencyDays: _freqDays, notes: _notesCtrl.text.trim(), isLent: _isLent);
            Navigator.pop(context);
          },
          child: const Text('Registrar deuda'),
        )),
      ])),
    );
  }
}
