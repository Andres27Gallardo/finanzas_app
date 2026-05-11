import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';
import '../widgets/transaction_card.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});
  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}
class _TransactionsTabState extends State<TransactionsTab> {
  String _filter = 'month'; TransactionType? _typeFilter;
  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanceProvider>();
    final filtered = p.getFilteredTransactions(filter: _filter, type: _typeFilter);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [
          for (final e in {'day':'Hoy','week':'Semana','month':'Mes','year':'Año'}.entries)
            Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(e.value), selected: _filter == e.key, onSelected: (_) => setState(() => _filter = e.key), selectedColor: theme.colorScheme.primary.withOpacity(0.2))),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('Ingresos'), selected: _typeFilter == TransactionType.income, selectedColor: Colors.green.withOpacity(0.2), onSelected: (s) => setState(() => _typeFilter = s ? TransactionType.income : null)),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('Gastos'), selected: _typeFilter == TransactionType.expense, selectedColor: Colors.red.withOpacity(0.2), onSelected: (s) => setState(() => _typeFilter = s ? TransactionType.expense : null)),
        ])),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Mantén presionado para editar o eliminar', style: TextStyle(fontSize: 11, color: Colors.grey))),
        const SizedBox(height: 4),
        Expanded(child: filtered.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('🔍', style: TextStyle(fontSize: 48)), const SizedBox(height: 12), Text('Sin movimientos', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey))]))
          : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), itemCount: filtered.length, itemBuilder: (_, i) => TransactionCard(transaction: filtered[i]))),
      ]),
    );
  }
}
