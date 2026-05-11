import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  String _filter = 'month';
  int _view = 0; // 0=general, 1=gastos, 2=ingresos, 3=cuentas

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanceProvider>();
    final fmt = NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);
    final theme = Theme.of(context);

    final income = p
        .getFilteredTransactions(filter: _filter, type: TransactionType.income)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = p
        .getFilteredTransactions(filter: _filter, type: TransactionType.expense)
        .fold<double>(0, (s, t) => s + t.amount);

    final spending = p.getCategorySpending(_filter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in {
                    'day': 'Hoy',
                    'week': 'Semana',
                    'month': 'Mes',
                    'year': 'Año'
                  }.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: _filter == entry.key,
                        onSelected: (_) => setState(() => _filter = entry.key),
                        selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // View tabs
            Row(
              children: [
                for (final tab in [
                  '📊 General',
                  '📉 Gastos',
                  '📈 Ingresos',
                  '🏦 Cuentas'
                ])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _view = ['📊 General', '📉 Gastos', '📈 Ingresos', '🏦 Cuentas'].indexOf(tab)),
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _view ==
                                  ['📊 General', '📉 Gastos', '📈 Ingresos', '🏦 Cuentas'].indexOf(tab)
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          tab,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _view ==
                                    ['📊 General', '📉 Gastos', '📈 Ingresos', '🏦 Cuentas'].indexOf(tab)
                                ? Colors.white
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Ingresos',
                    value: fmt.format(income),
                    color: Colors.green,
                    icon: '📈',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Gastos',
                    value: fmt.format(expense),
                    color: Colors.red,
                    icon: '📉',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Balance',
                    value: fmt.format(income - expense),
                    color: (income - expense) >= 0 ? Colors.blue : Colors.orange,
                    icon: '💰',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Charts based on view
            if (_view == 0) _buildGeneralChart(income, expense),
            if (_view == 1) _buildCategoryChart(spending, p, false),
            if (_view == 2) _buildIncomeChart(p),
            if (_view == 3) _buildAccountsChart(p, fmt),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralChart(double income, double expense) {
    if (income == 0 && expense == 0) {
      return const _EmptyChart();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresos vs Gastos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: income,
                      color: Colors.green.shade400,
                      title: income > 0
                          ? '${((income / (income + expense)) * 100).toStringAsFixed(0)}%'
                          : '',
                      radius: 80,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      value: expense,
                      color: Colors.red.shade400,
                      title: expense > 0
                          ? '${((expense / (income + expense)) * 100).toStringAsFixed(0)}%'
                          : '',
                      radius: 80,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend(color: Colors.green.shade400, label: 'Ingresos'),
                const SizedBox(width: 24),
                _Legend(color: Colors.red.shade400, label: 'Gastos'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(
      Map<String, double> spending, dynamic p, bool isIncome) {
    if (spending.isEmpty) return const _EmptyChart();

    final sorted = spending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    final fmt = NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gastos por categoría',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...top.map((e) {
              final cat = p.getCategoryById(e.key);
              final total = spending.values.fold<double>(0, (s, v) => s + v);
              final pct = total > 0 ? e.value / total : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(cat?.icon ?? '💸',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(cat?.name ?? 'Otro',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Text(fmt.format(e.value),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          cat != null ? Color(cat.colorValue) : Colors.grey,
                        ),
                      ),
                    ),
                    Text('${(pct * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeChart(dynamic p) {
    final incomeTx = p.getFilteredTransactions(
        filter: _filter, type: TransactionType.income);
    final Map<String, double> byCategory = {};
    for (final t in incomeTx) {
      byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
    }
    return _buildCategoryChart(byCategory, p, true);
  }

  Widget _buildAccountsChart(dynamic p, NumberFormat fmt) {
    if (p.accounts.isEmpty) return const _EmptyChart();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saldo por cuenta',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...p.accounts.map<Widget>((acc) {
              final total = p.totalBalance > 0 ? p.totalBalance : 1.0;
              final pct = (acc.balance / total).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Text(acc.icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(acc.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              Text(fmt.format(acc.balance),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: acc.balance >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(acc.colorValue)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Text('📊', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text('Sin datos para mostrar',
                  style: TextStyle(color: Colors.grey)),
              SizedBox(height: 4),
              Text('Agrega transacciones para ver tus gráficas',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
