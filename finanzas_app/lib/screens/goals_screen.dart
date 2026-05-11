import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/goal.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanceProvider>();
    final fmt = NumberFormat.currency(locale: 'es', symbol: p.currency, decimalDigits: 2);

    // ✅ Sincronizar savedAmount con balance real de la cuenta
    for (final g in p.goals) {
      g.savedAmount = p.getAccountBalance(g.accountId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Objetivos financieros', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showAdd(context))],
      ),
      body: p.goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text('No tienes objetivos aún', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text(
                    'Crea una meta y el progreso se actualiza\nautomáticamente con tu saldo real',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showAdd(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear objetivo'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: p.goals.length,
              itemBuilder: (_, i) {
                final g = p.goals[i];
                // ✅ Progreso basado en saldo real de la cuenta
                final accountBalance = p.getAccountBalance(g.accountId);
                g.savedAmount = accountBalance;
                final pct = g.progress;
                final remaining = g.targetAmount - accountBalance;
                final acc = p.getAccountById(g.accountId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Text(g.icon, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  if (acc != null)
                                    Text(
                                      '${acc.icon} ${acc.name}: ${fmt.format(accountBalance)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  if (g.deadline != null)
                                    Text(
                                      'Fecha límite: ${DateFormat('dd/MM/yyyy').format(g.deadline!)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                            if (g.isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('✅ Completado', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Eliminar objetivo'),
                                    content: Text('¿Eliminar "${g.name}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (ok == true && context.mounted) {
                                  context.read<FinanceProvider>().deleteGoal(g.id);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Progreso
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(fmt.format(accountBalance), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            Text('Meta: ${fmt.format(g.targetAmount)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              g.isCompleted ? Colors.green : const Color(0xFF6C63FF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${(pct * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              g.isCompleted
                                  ? '¡Meta alcanzada! 🎉'
                                  : 'Faltan ${fmt.format(remaining > 0 ? remaining : 0)}',
                              style: TextStyle(
                                color: g.isCompleted ? Colors.green : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        if (!g.isCompleted) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Color(0xFF6C63FF)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'El progreso se actualiza automáticamente con el saldo de "${acc?.name ?? 'la cuenta'}"',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF6C63FF)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddGoalSheet(),
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  const _AddGoalSheet();
  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _iconCtrl = TextEditingController();
  String? _accountId;
  DateTime? _deadline;

  @override
  void dispose() { _nameCtrl.dispose(); _amountCtrl.dispose(); _iconCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanceProvider>();
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nuevo Objetivo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('El progreso se calcula automáticamente desde el saldo de la cuenta elegida.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre del objetivo', hintText: 'Ej: Bicicleta, Viaje, Emergencia...', prefixIcon: Icon(Icons.flag_outlined)), textCapitalization: TextCapitalization.sentences),
          const SizedBox(height: 12),
          TextField(controller: _iconCtrl, decoration: const InputDecoration(labelText: 'Emoji (opcional)', hintText: '🎯  🚲  ✈️  🏠', prefixIcon: Icon(Icons.emoji_emotions_outlined)), style: const TextStyle(fontSize: 22), maxLength: 4),
          const SizedBox(height: 4),
          TextField(controller: _amountCtrl, decoration: InputDecoration(labelText: 'Monto objetivo', prefixText: '${p.currency} ', prefixIcon: const Icon(Icons.attach_money)), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _accountId,
            decoration: const InputDecoration(labelText: 'Cuenta a monitorear', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
            items: p.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.icon} ${a.name}'))).toList(),
            onChanged: (v) => setState(() => _accountId = v),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 5)));
              if (d != null) setState(() => _deadline = d);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Fecha límite (opcional)', prefixIcon: Icon(Icons.calendar_today_outlined)),
              child: Text(_deadline != null ? DateFormat('dd/MM/yyyy').format(_deadline!) : 'Sin fecha límite', style: TextStyle(color: _deadline != null ? null : Colors.grey)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final name = _nameCtrl.text.trim();
                final amount = double.tryParse(_amountCtrl.text) ?? 0;
                if (name.isEmpty || amount <= 0 || _accountId == null) return;
                final icon = _iconCtrl.text.trim();
                context.read<FinanceProvider>().addGoal(name: name, icon: icon.isEmpty ? '🎯' : icon, targetAmount: amount, accountId: _accountId!, deadline: _deadline);
                Navigator.pop(context);
              },
              child: const Text('Crear objetivo'),
            ),
          ),
        ],
      ),
    );
  }
}
