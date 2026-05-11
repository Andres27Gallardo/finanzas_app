import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}
class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();
  final _expensesCtrl = TextEditingController();
  String _occupation = 'Trabajo', _mainGoal = '🎯 Ahorrar';
  bool _loading = false;

  @override
  void dispose() { _ageCtrl.dispose(); _incomeCtrl.dispose(); _expensesCtrl.dispose(); super.dispose(); }

  Widget _chip(String label, String group, Function(String) onTap) {
    final sel = group == label;
    return GestureDetector(onTap: () => onTap(label), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: sel ? const Color(0xFF6C63FF) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? const Color(0xFF6C63FF) : Colors.transparent)), child: Text(label, style: TextStyle(color: sel ? Colors.white : null, fontWeight: sel ? FontWeight.w600 : FontWeight.normal, fontSize: 13))));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<FinanceProvider>();
    return Scaffold(body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 40), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Column(children: [
        const Text('🧠', style: TextStyle(fontSize: 56)), const SizedBox(height: 12),
        Text('Hola, ${p.userProfile?.name ?? ''}!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Cuéntame sobre ti para personalizar\ntus recomendaciones con IA', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      ])),
      const SizedBox(height: 32),
      TextFormField(controller: _ageCtrl, decoration: const InputDecoration(labelText: 'Edad', prefixIcon: Icon(Icons.cake_outlined)), keyboardType: TextInputType.number, validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null),
      const SizedBox(height: 20),
      Text('¿A qué te dedicas?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: ['Trabajo','Estudio','Ambos','Otro'].map((o) => _chip(o, _occupation, (v) => setState(() => _occupation = v))).toList()),
      const SizedBox(height: 20),
      TextFormField(controller: _incomeCtrl, decoration: InputDecoration(labelText: 'Ingresos mensuales aprox.', prefixText: '${p.currency} ', prefixIcon: const Icon(Icons.arrow_upward, color: Colors.green)), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null),
      const SizedBox(height: 16),
      TextFormField(controller: _expensesCtrl, decoration: InputDecoration(labelText: 'Gastos mensuales aprox.', prefixText: '${p.currency} ', prefixIcon: const Icon(Icons.arrow_downward, color: Colors.red)), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null),
      const SizedBox(height: 20),
      Text('¿Objetivo principal?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: ['🎯 Ahorrar','📊 Controlar gastos','📈 Invertir','🔄 Uso general'].map((o) => _chip(o, _mainGoal, (v) => setState(() => _mainGoal = v))).toList()),
      const SizedBox(height: 40),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _loading ? null : () async {
          if (!_formKey.currentState!.validate()) return;
          setState(() => _loading = true);
          await context.read<FinanceProvider>().completeProfile(age: int.tryParse(_ageCtrl.text) ?? 0, occupation: _occupation, monthlyIncome: double.tryParse(_incomeCtrl.text) ?? 0, monthlyExpenses: double.tryParse(_expensesCtrl.text) ?? 0, mainGoal: _mainGoal);
          if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
        },
        child: _loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Comenzar 🚀'),
      )),
    ])))));
  }
}
