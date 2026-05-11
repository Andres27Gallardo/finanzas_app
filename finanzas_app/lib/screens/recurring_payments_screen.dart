import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/recurring_payment.dart';

class RecurringPaymentsScreen extends StatelessWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanceProvider>();
    final fmt = NumberFormat.currency(locale: 'es', symbol: p.currency, decimalDigits: 2);
    final payments = p.recurringPayments;
    final overdue = payments.where((r) => r.isActive && r.isOverdue).toList();
    final dueToday = payments.where((r) => r.isActive && r.isDueToday).toList();
    final upcoming = payments.where((r) => r.isActive && !r.isOverdue && !r.isDueToday).toList();
    final inactive = payments.where((r) => !r.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos Frecuentes', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showAdd(context))],
      ),
      body: payments.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('💳', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text('No tienes pagos frecuentes', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Agrega Netflix, luz, internet,\no cualquier cobro recurrente', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              ElevatedButton.icon(onPressed: () => _showAdd(context), icon: const Icon(Icons.add), label: const Text('Agregar pago')),
            ]))
          : ListView(padding: const EdgeInsets.all(16), children: [
              if (overdue.isNotEmpty) ...[
                _Header('🔴 Vencidos', Colors.red),
                const SizedBox(height: 8),
                ...overdue.map((r) => _Card(r, fmt, context)),
                const SizedBox(height: 16),
              ],
              if (dueToday.isNotEmpty) ...[
                _Header('🟡 Vence hoy', Colors.orange),
                const SizedBox(height: 8),
                ...dueToday.map((r) => _Card(r, fmt, context)),
                const SizedBox(height: 16),
              ],
              if (upcoming.isNotEmpty) ...[
                _Header('🟢 Próximos', Colors.green),
                const SizedBox(height: 8),
                ...upcoming.map((r) => _Card(r, fmt, context)),
                const SizedBox(height: 16),
              ],
              if (inactive.isNotEmpty) ...[
                _Header('⚫ Inactivos', Colors.grey),
                const SizedBox(height: 8),
                ...inactive.map((r) => _Card(r, fmt, context)),
              ],
            ]),
    );
  }

  Widget _Header(String t, Color c) => Text(t, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: c));

  Widget _Card(RecurringPayment r, NumberFormat fmt, BuildContext context) {
    Color statusColor;
    String statusText;
    if (!r.isActive) { statusColor = Colors.grey; statusText = 'Inactivo'; }
    else if (r.isOverdue) { statusColor = Colors.red; statusText = 'Vencido hace ${-r.daysUntilDue} día(s)'; }
    else if (r.isDueToday) { statusColor = Colors.orange; statusText = '¡Vence hoy!'; }
    else { statusColor = Colors.green; statusText = 'En ${r.daysUntilDue} día(s)'; }

    return Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(r.icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: r.iAmPaying ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(r.iAmPaying ? '💸 Yo pago' : '💰 Me pagan', style: TextStyle(fontSize: 10, color: r.iAmPaying ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
            ]),
            if (r.description.isNotEmpty) Text(r.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ])),
          Switch(value: r.isActive, onChanged: (_) => context.read<FinanceProvider>().toggleRecurringPayment(r.id), activeColor: const Color(0xFF6C63FF), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(r.isFixedAmount && r.fixedAmount != null ? fmt.format(r.fixedAmount) : 'Monto variable', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)))),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(r.frequencyLabel, style: const TextStyle(fontSize: 12, color: Colors.grey))),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(Icons.circle, size: 10, color: statusColor), const SizedBox(width: 4), Text(statusText, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600))]),
          Text('Próximo: ${DateFormat('dd/MM/yyyy').format(r.nextDueDate)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          if (r.isActive) ...[
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _showPay(context, r, fmt),
              icon: const Icon(Icons.check, size: 16),
              label: Text(r.iAmPaying ? 'Registrar pago' : 'Registrar cobro', style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), backgroundColor: r.iAmPaying ? Colors.red.shade400 : Colors.green.shade400),
            )),
            const SizedBox(width: 8),
          ],
          IconButton(icon: const Icon(Icons.edit_outlined, color: Color(0xFF6C63FF), size: 20), onPressed: () => _showAdd(context, edit: r)),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _delete(context, r)),
        ]),
      ]),
    ));
  }

  void _showPay(BuildContext context, RecurringPayment r, NumberFormat fmt) {
    final ctrl = TextEditingController(text: r.isFixedAmount && r.fixedAmount != null ? r.fixedAmount.toString() : '');
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('${r.iAmPaying ? 'Registrar pago' : 'Registrar cobro'}: ${r.name}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(r.isFixedAmount && r.fixedAmount != null ? 'Monto fijo: ${fmt.format(r.fixedAmount)}' : 'Ingresa el monto recibido/pagado', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 12),
        TextField(controller: ctrl, decoration: InputDecoration(labelText: 'Monto', prefixText: '${context.read<FinanceProvider>().currency} '), keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () async {
          final amount = double.tryParse(ctrl.text) ?? 0;
          if (amount <= 0) return;
          await context.read<FinanceProvider>().registerRecurringPayment(r.id, amount);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${r.iAmPaying ? 'Pago' : 'Cobro'} registrado: ${fmt.format(amount)}'), backgroundColor: Colors.green));
          }
        }, child: const Text('Registrar')),
      ],
    ));
  }

  void _delete(BuildContext context, RecurringPayment r) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Eliminar'), content: Text('¿Eliminar "${r.name}"?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red)))],
    ));
    if (ok == true && context.mounted) context.read<FinanceProvider>().deleteRecurringPayment(r.id);
  }

  void _showAdd(BuildContext context, {RecurringPayment? edit}) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _AddSheet(edit: edit));
  }
}

class _AddSheet extends StatefulWidget {
  final RecurringPayment? edit;
  const _AddSheet({this.edit});
  @override State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _iconCtrl = TextEditingController();
  final _customDaysCtrl = TextEditingController();
  final _dayOfMonthCtrl = TextEditingController();

  bool _isFixedAmount = true, _iAmPaying = true, _useCustomDays = false, _useDayOfMonth = false;
  int _frequencyDays = 30;
  String? _categoryId, _accountId;
  DateTime _nextDueDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    final p = context.read<FinanceProvider>();
    if (widget.edit != null) {
      final e = widget.edit!;
      _nameCtrl.text = e.name; _descCtrl.text = e.description; _iconCtrl.text = e.icon;
      _isFixedAmount = e.isFixedAmount; _iAmPaying = e.iAmPaying;
      if (e.fixedAmount != null) _amountCtrl.text = e.fixedAmount.toString();
      _frequencyDays = e.frequencyDays; _categoryId = e.categoryId; _accountId = e.accountId;
      _nextDueDate = e.nextDueDate;
      if (e.dayOfMonth != null) { _useDayOfMonth = true; _dayOfMonthCtrl.text = e.dayOfMonth.toString(); }
    } else {
      if (p.expenseCategories.isNotEmpty) _categoryId = p.expenseCategories.first.id;
      if (p.accounts.isNotEmpty) _accountId = p.accounts.first.id;
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); _amountCtrl.dispose(); _iconCtrl.dispose(); _customDaysCtrl.dispose(); _dayOfMonthCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanceProvider>();
    final isEdit = widget.edit != null;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isEdit ? 'Editar pago frecuente' : 'Nuevo pago frecuente', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Yo pago / Me pagan
        const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => setState(() => _iAmPaying = true), child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _iAmPaying ? Colors.red.shade400 : Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.4))), child: Column(children: [const Text('💸', style: TextStyle(fontSize: 20)), Text('Yo pago', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _iAmPaying ? Colors.white : Colors.red))])))),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(onTap: () => setState(() => _iAmPaying = false), child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: !_iAmPaying ? Colors.green.shade400 : Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.withOpacity(0.4))), child: Column(children: [const Text('💰', style: TextStyle(fontSize: 20)), Text('Me pagan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: !_iAmPaying ? Colors.white : Colors.green))])))),
        ]),
        const SizedBox(height: 16),

        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre', hintText: 'Netflix, Luz, Renta...', prefixIcon: Icon(Icons.label_outline)), textCapitalization: TextCapitalization.sentences),
        const SizedBox(height: 12),
        TextField(controller: _iconCtrl, decoration: const InputDecoration(labelText: 'Emoji (opcional)', hintText: '💳 📺 💡 🏋️', prefixIcon: Icon(Icons.emoji_emotions_outlined)), style: const TextStyle(fontSize: 22), maxLength: 4),
        TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Descripción (opcional)', prefixIcon: Icon(Icons.notes_outlined))),
        const SizedBox(height: 12),

        // Monto fijo / variable
        const Text('Monto', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => setState(() => _isFixedAmount = true), child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: _isFixedAmount ? const Color(0xFF6C63FF) : const Color(0xFF6C63FF).withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.4))), child: Column(children: [Icon(Icons.lock_outline, color: _isFixedAmount ? Colors.white : const Color(0xFF6C63FF), size: 18), Text('Fijo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _isFixedAmount ? Colors.white : const Color(0xFF6C63FF)))])))),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(onTap: () => setState(() => _isFixedAmount = false), child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: !_isFixedAmount ? Colors.orange : Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.withOpacity(0.4))), child: Column(children: [Icon(Icons.edit_outlined, color: !_isFixedAmount ? Colors.white : Colors.orange, size: 18), Text('Variable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: !_isFixedAmount ? Colors.white : Colors.orange))])))),
        ]),
        if (_isFixedAmount) ...[const SizedBox(height: 12), TextField(controller: _amountCtrl, decoration: InputDecoration(labelText: 'Monto', prefixText: '${p.currency} ', prefixIcon: const Icon(Icons.attach_money)), keyboardType: const TextInputType.numberWithOptions(decimal: true))],
        const SizedBox(height: 12),

        // Frecuencia
        const Text('Frecuencia', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        // Día específico del mes
        SwitchListTile(
          title: const Text('Día fijo del mes', style: TextStyle(fontSize: 14)),
          subtitle: const Text('Ej: cada día 5, día 15...', style: TextStyle(fontSize: 11)),
          value: _useDayOfMonth, onChanged: (v) => setState(() { _useDayOfMonth = v; _useCustomDays = false; }),
          activeColor: const Color(0xFF6C63FF), contentPadding: EdgeInsets.zero,
        ),
        if (_useDayOfMonth)
          TextField(controller: _dayOfMonthCtrl, decoration: const InputDecoration(labelText: 'Día del mes (1-31)', hintText: 'Ej: 5, 15, 30', prefixIcon: Icon(Icons.calendar_today)), keyboardType: TextInputType.number),
        if (!_useDayOfMonth) ...[
          DropdownButtonFormField<int>(
            value: _useCustomDays ? 0 : _frequencyDays,
            decoration: const InputDecoration(labelText: 'Cada cuánto', prefixIcon: Icon(Icons.repeat)),
            items: const [
              DropdownMenuItem(value: 7, child: Text('Semanal (7 días)')),
              DropdownMenuItem(value: 14, child: Text('Quincenal (14 días)')),
              DropdownMenuItem(value: 30, child: Text('Mensual (30 días)')),
              DropdownMenuItem(value: 60, child: Text('Bimestral (60 días)')),
              DropdownMenuItem(value: 90, child: Text('Trimestral (90 días)')),
              DropdownMenuItem(value: 180, child: Text('Semestral (180 días)')),
              DropdownMenuItem(value: 365, child: Text('Anual (365 días)')),
              DropdownMenuItem(value: 0, child: Text('Personalizado...')),
            ],
            onChanged: (v) { if (v == 0) { setState(() => _useCustomDays = true); } else { setState(() { _useCustomDays = false; _frequencyDays = v!; }); } },
          ),
          if (_useCustomDays) ...[const SizedBox(height: 8), TextField(controller: _customDaysCtrl, decoration: const InputDecoration(labelText: 'Cada cuántos días', prefixIcon: Icon(Icons.calendar_today)), keyboardType: TextInputType.number, onChanged: (v) { final d = int.tryParse(v); if (d != null && d > 0) _frequencyDays = d; })],
        ],
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(value: _categoryId, decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category_outlined)), items: p.expenseCategories.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.icon} ${c.name}'))).toList(), onChanged: (v) => setState(() => _categoryId = v)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _accountId, decoration: const InputDecoration(labelText: 'Cuenta vinculada', prefixIcon: Icon(Icons.account_balance_wallet_outlined)), items: p.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.icon} ${a.name}'))).toList(), onChanged: (v) => setState(() => _accountId = v)),
        const SizedBox(height: 12),

        InkWell(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _nextDueDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 5)));
            if (d != null) setState(() => _nextDueDate = d);
          },
          child: InputDecorator(decoration: const InputDecoration(labelText: 'Próximo vencimiento', prefixIcon: Icon(Icons.calendar_today_outlined)), child: Text(DateFormat('dd/MM/yyyy').format(_nextDueDate), style: const TextStyle(fontSize: 15))),
        ),
        const SizedBox(height: 24),

        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty || _categoryId == null || _accountId == null) return;
            if (_isFixedAmount && _amountCtrl.text.isEmpty) return;
            final icon = _iconCtrl.text.trim().isEmpty ? (_iAmPaying ? '💸' : '💰') : _iconCtrl.text.trim();
            final amount = _isFixedAmount ? double.tryParse(_amountCtrl.text) : null;
            int? dayOfMonth;
            if (_useDayOfMonth) { dayOfMonth = int.tryParse(_dayOfMonthCtrl.text); if (dayOfMonth == null || dayOfMonth < 1 || dayOfMonth > 31) return; }

            if (isEdit) {
              context.read<FinanceProvider>().editRecurringPayment(widget.edit!.id, name: name, description: _descCtrl.text.trim(), icon: icon, fixedAmount: amount, isFixedAmount: _isFixedAmount, frequencyDays: _frequencyDays, dayOfMonth: dayOfMonth, categoryId: _categoryId!, accountId: _accountId!, nextDueDate: _nextDueDate, iAmPaying: _iAmPaying);
            } else {
              context.read<FinanceProvider>().addRecurringPayment(name: name, description: _descCtrl.text.trim(), icon: icon, fixedAmount: amount, isFixedAmount: _isFixedAmount, frequencyDays: _frequencyDays, dayOfMonth: dayOfMonth, categoryId: _categoryId!, accountId: _accountId!, nextDueDate: _nextDueDate, iAmPaying: _iAmPaying);
            }
            Navigator.pop(context);
          },
          child: Text(isEdit ? 'Guardar cambios' : 'Crear pago frecuente'),
        )),
      ])),
    );
  }
}
