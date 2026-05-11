import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../screens/add_transaction_screen.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final p = context.read<FinanceProvider>();
    final cat = p.getCategoryById(transaction.categoryId);
    final acc = p.getAccountById(transaction.accountId);
    final toAcc = transaction.toAccountId != null
        ? p.getAccountById(transaction.toAccountId!)
        : null;
    final fmt = NumberFormat.currency(locale: 'es', symbol: p.currency, decimalDigits: 2);

    Color amountColor;
    String prefix;
    // ✅ Fix #4: transferencia no muestra categoría
    String subtitleText;
    String leadingEmoji;

    switch (transaction.type) {
      case TransactionType.income:
        amountColor = Colors.green;
        prefix = '+';
        subtitleText = cat?.name ?? 'Sin categoría';
        leadingEmoji = cat?.icon ?? '💰';
        break;
      case TransactionType.expense:
        amountColor = Colors.red;
        prefix = '-';
        subtitleText = cat?.name ?? 'Sin categoría';
        leadingEmoji = cat?.icon ?? '💸';
        break;
      case TransactionType.transfer:
        amountColor = Colors.blue;
        prefix = '↔';
        // ✅ Muestra cuenta origen → cuenta destino
        subtitleText = '${acc?.name ?? 'Cuenta'} → ${toAcc?.name ?? 'Destino'}';
        leadingEmoji = '🔄';
        break;
    }

    return GestureDetector(
      onLongPress: () => _showOptions(context, p),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: transaction.type == TransactionType.transfer
                  ? Colors.blue.withOpacity(0.15)
                  : (cat != null ? Color(cat.colorValue) : Colors.grey).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(leadingEmoji, style: const TextStyle(fontSize: 22))),
          ),
          title: Text(
            transaction.description,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(subtitleText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                transaction.type == TransactionType.transfer
                    ? DateFormat('dd MMM HH:mm', 'es').format(transaction.date)
                    : '${acc?.icon ?? ''} ${acc?.name ?? ''} · ${DateFormat('dd MMM HH:mm', 'es').format(transaction.date)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$prefix${fmt.format(transaction.amount)}',
                style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Text('mantén para editar', style: TextStyle(fontSize: 8, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, FinanceProvider p) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(transaction.description,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Color(0xFF6C63FF)),
              title: const Text('Editar transacción'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(editTransaction: transaction)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Eliminar transacción'),
                    content: Text('¿Eliminar "${transaction.description}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.pop(context, true),
                          child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (ok == true && context.mounted) p.deleteTransaction(transaction.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
