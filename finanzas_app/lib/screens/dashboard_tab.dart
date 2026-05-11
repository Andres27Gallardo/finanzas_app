import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../widgets/transaction_card.dart';
import 'chatbot_screen.dart';
import 'charts_screen.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanceProvider>();
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(locale: 'es', symbol: p.currency, decimalDigits: 2);

    String healthEmoji, healthText;
    Color healthColor;
    switch (p.financialHealth) {
      case 'good':
        healthEmoji = '🟢'; healthText = 'Buena'; healthColor = Colors.green;
        break;
      case 'medium':
        healthEmoji = '🟡'; healthText = 'Regular'; healthColor = Colors.orange;
        break;
      case 'bad':
        healthEmoji = '🔴'; healthText = 'Riesgosa'; healthColor = Colors.red;
        break;
      default:
        healthEmoji = '⚪'; healthText = 'Sin datos'; healthColor = Colors.grey;
    }

    return SafeArea(
      child: Column(
        children: [
          // ─── Header ───────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C63FF), Color(0xFF8B80FF)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${p.userProfile?.name.split(' ').first ?? 'Usuario'} 👋',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const Text(
                          'Tu resumen financiero',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                      ),
                      icon: const Text('🤖', style: TextStyle(fontSize: 28)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  fmt.format(p.totalBalance),
                  style: const TextStyle(
                    color: Colors.white, fontSize: 32,
                    fontWeight: FontWeight.bold, letterSpacing: -1,
                  ),
                ),
                Row(
                  children: [
                    const Text('Balance general', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(p.periodLabel, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Mini('📈', 'Ingresos', fmt.format(p.periodIncome), Colors.greenAccent),
                    const SizedBox(width: 20),
                    _Mini('📉', 'Gastos', fmt.format(p.periodExpenses), Colors.redAccent.shade100),
                  ],
                ),
                const SizedBox(height: 12),
                // Selector de período
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final e in {'day': 'Hoy', 'week': 'Semana', 'month': 'Mes', 'year': 'Año'}.entries)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => p.setDashboardPeriod(e.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: p.dashboardPeriod == e.key
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                e.value,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: p.dashboardPeriod == e.key
                                      ? const Color(0xFF6C63FF)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Body ─────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Salud + Gráficas
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Text(healthEmoji, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Salud', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  Text(healthText, style: TextStyle(fontWeight: FontWeight.bold, color: healthColor)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChartsScreen()),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const Text('📊', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Gráficas', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text(
                                      'Ver análisis',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  'Movimientos recientes',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mantén presionado para editar o eliminar',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 8),

                if (p.recentTransactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Text('💸', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 12),
                        Text(
                          'No hay transacciones aún',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Toca + para agregar tu primer movimiento',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else
                  ...p.recentTransactions.map((t) => TransactionCard(transaction: t)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String icon, label, value;
  final Color color;
  const _Mini(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}
