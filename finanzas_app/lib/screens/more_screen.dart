import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/finance_provider.dart';
import '../models/category.dart';
import 'login_screen.dart';
import 'goals_screen.dart';
import 'export_screen.dart';
import 'debts_screen.dart';
import 'recurring_payments_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanceProvider>();
    final overdueCount = p.recurringPayments.where((r) => r.isActive && (r.isOverdue || r.isDueToday)).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Más', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Perfil
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            CircleAvatar(radius: 28, backgroundColor: const Color(0xFF6C63FF),
              child: Text((p.userProfile?.name.isNotEmpty ?? false) ? p.userProfile!.name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.userProfile?.name ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(p.userProfile?.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(p.userProfile?.mainGoal ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF6C63FF), fontWeight: FontWeight.w500))),
            ])),
          ]))),
          const SizedBox(height: 16),

          _Label('⚙️ Configuración'),
          Card(child: Column(children: [
            SwitchListTile(title: const Text('Modo oscuro'), secondary: const Text('🌙', style: TextStyle(fontSize: 22)), value: p.isDarkMode, onChanged: (_) => p.toggleDarkMode()),
            const Divider(height: 1, indent: 16),
            ListTile(
              leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(p.currency, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
              title: const Text('Moneda'), subtitle: Text('Actual: ${p.currency}'),
              trailing: const Icon(Icons.chevron_right), onTap: () => _showCurrency(context, p),
            ),
          ])),
          const SizedBox(height: 16),

          _Label('📋 Gestión'),
          Card(child: Column(children: [
            ListTile(
              leading: const Text('🎯', style: TextStyle(fontSize: 22)),
              title: const Text('Objetivos financieros'),
              subtitle: Text('${p.goals.length} objetivo(s)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
            ),
            const Divider(height: 1, indent: 16),
            ListTile(
              leading: const Text('🤝', style: TextStyle(fontSize: 22)),
              title: const Text('Deudas y préstamos'),
              subtitle: Text('${p.debts.where((d) => !d.isCompleted).length} activa(s)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtsScreen())),
            ),
            const Divider(height: 1, indent: 16),
            // ✅ Pagos frecuentes con badge de alerta
            ListTile(
              leading: Stack(children: [
                const Text('💳', style: TextStyle(fontSize: 22)),
                if (overdueCount > 0)
                  Positioned(right: 0, top: 0, child: Container(
                    width: 14, height: 14,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Center(child: Text('$overdueCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                  )),
              ]),
              title: const Text('Pagos frecuentes'),
              subtitle: Text('${p.recurringPayments.where((r) => r.isActive).length} activo(s)${overdueCount > 0 ? ' · $overdueCount vence(n) hoy' : ''}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringPaymentsScreen())),
            ),
            const Divider(height: 1, indent: 16),
            ListTile(
              leading: const Text('📊', style: TextStyle(fontSize: 22)),
              title: const Text('Exportar a Excel'),
              subtitle: const Text('Comparte por WhatsApp, Drive...'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportScreen())),
            ),
          ])),
          const SizedBox(height: 16),

          _Label('🏷️ Categorías'),
          Card(child: Column(children: [
            ListTile(
              leading: const Text('📉', style: TextStyle(fontSize: 22)),
              title: const Text('Categorías de Gastos'),
              subtitle: Text('${p.expenseCategories.length} categorías'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen(isIncome: false))),
            ),
            const Divider(height: 1, indent: 16),
            ListTile(
              leading: const Text('📈', style: TextStyle(fontSize: 22)),
              title: const Text('Categorías de Ingresos'),
              subtitle: Text('${p.incomeCategories.length} categorías'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen(isIncome: true))),
            ),
          ])),
          const SizedBox(height: 16),

          _Label('⚠️ Zona peligrosa'),
          Card(child: ListTile(
            leading: const Text('🔄', style: TextStyle(fontSize: 22)),
            title: const Text('Restaurar aplicación', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Borra cuentas, movimientos, deudas y objetivos'),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: () async {
              final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                title: const Text('⚠️ Restaurar aplicación'),
                content: const Text('¿Estás seguro?\n\nEsto eliminará PERMANENTEMENTE todos los datos.\nEsta acción NO se puede deshacer.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('SÍ, RESTAURAR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                ],
              ));
              if (ok == true && context.mounted) {
                await context.read<FinanceProvider>().resetAllData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Aplicación restaurada'), backgroundColor: Colors.green));
              }
            },
          )),
          const SizedBox(height: 16),

          const Card(child: Padding(padding: EdgeInsets.all(16), child: Column(children: [
            Text('💰', style: TextStyle(fontSize: 40)), SizedBox(height: 8),
            Text('My Money IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('v5.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]))),
          const SizedBox(height: 16),

          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                title: const Text('Cerrar sesión'),
                content: const Text('¿Seguro que quieres salir?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salir', style: TextStyle(color: Colors.red))),
                ],
              ));
              if (ok == true && context.mounted) {
                await context.read<FinanceProvider>().logout();
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: const Icon(Icons.logout), label: const Text('Cerrar sesión'),
          )),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  void _showCurrency(BuildContext context, FinanceProvider p) {
    final currencies = [
      {'s':'\$','n':'Dólar (USD)'},{'s':'Bs','n':'Boliviano (BOB)'},{'s':'€','n':'Euro (EUR)'},
      {'s':'£','n':'Libra (GBP)'},{'s':'S/.','n':'Sol (PEN)'},{'s':'CLP\$','n':'Peso chileno'},
      {'s':'COP\$','n':'Peso colombiano'},{'s':'MXN\$','n':'Peso mexicano'},
      {'s':'R\$','n':'Real (BRL)'},{'s':'ARS\$','n':'Peso argentino'},
    ];
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.6, maxChildSize: 0.85,
        builder: (_, ctrl) => ListView(controller: ctrl, padding: const EdgeInsets.all(16), children: [
          const SizedBox(height: 8),
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Center(child: Text('Selecciona tu moneda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          const SizedBox(height: 8),
          ...currencies.map((c) => ListTile(
            leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(c['s']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
            title: Text(c['n']!),
            trailing: p.currency == c['s'] ? const Icon(Icons.check_circle, color: Color(0xFF6C63FF)) : null,
            onTap: () { p.setCurrency(c['s']!); Navigator.pop(context); },
          )),
        ]),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String label; const _Label(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
  );
}

class CategoriesScreen extends StatelessWidget {
  final bool isIncome;
  const CategoriesScreen({super.key, required this.isIncome});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanceProvider>();
    final cats = isIncome ? p.incomeCategories : p.expenseCategories;
    return Scaffold(
      appBar: AppBar(
        title: Text(isIncome ? 'Ingresos' : 'Gastos', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showAdd(context))],
      ),
      body: cats.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🏷️', style: TextStyle(fontSize: 56)), const SizedBox(height: 12),
              const Text('No hay categorías', style: TextStyle(color: Colors.grey)), const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: () => _showAdd(context), icon: const Icon(Icons.add), label: const Text('Nueva categoría')),
            ]))
          : Column(children: [
              const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('Mantén presionado para editar o eliminar', style: TextStyle(fontSize: 11, color: Colors.grey))),
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.all(16), itemCount: cats.length,
                itemBuilder: (_, i) {
                  final cat = cats[i];
                  return GestureDetector(
                    onLongPress: () => _showOptions(context, cat),
                    child: Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: Color(cat.colorValue).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text(cat.icon, style: const TextStyle(fontSize: 24)))),
                      title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 20, height: 20, decoration: BoxDecoration(color: Color(cat.colorValue), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        const Icon(Icons.more_vert, color: Colors.grey, size: 18),
                      ]),
                    )),
                  );
                },
              )),
            ]),
    );
  }

  void _showAdd(BuildContext context) => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _AddCategorySheet(isIncome: isIncome));

  void _showOptions(BuildContext context, CategoryModel cat) {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Row(children: [Text(cat.icon, style: const TextStyle(fontSize: 24)), const SizedBox(width: 10), Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
        const SizedBox(height: 16),
        ListTile(leading: const Icon(Icons.edit_outlined, color: Color(0xFF6C63FF)), title: const Text('Editar categoría'),
          onTap: () { Navigator.pop(context); showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _AddCategorySheet(isIncome: cat.isIncome, editCat: cat)); }),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Eliminar categoría', style: TextStyle(color: Colors.red)),
          onTap: () async {
            Navigator.pop(context);
            final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
              title: const Text('Eliminar categoría'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [Text('¿Eliminar "${cat.name}"?'), const SizedBox(height: 8), const Text('Al eliminar esta categoría serán eliminados todos los datos vinculados.', style: TextStyle(color: Colors.red, fontSize: 12))]),
              actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red)))],
            ));
            if (ok == true && context.mounted) context.read<FinanceProvider>().deleteCategory(cat.id);
          },
        ),
      ])));
  }
}

class _AddCategorySheet extends StatefulWidget {
  final bool isIncome; final CategoryModel? editCat;
  const _AddCategorySheet({required this.isIncome, this.editCat});
  @override State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  late TextEditingController _nameCtrl, _iconCtrl;
  late Color _color;
  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.editCat?.name ?? '');
    _iconCtrl = TextEditingController(text: widget.editCat?.icon ?? '');
    _color = widget.editCat != null ? Color(widget.editCat!.colorValue) : const Color(0xFF6C63FF);
  }
  @override void dispose() { _nameCtrl.dispose(); _iconCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.editCat != null ? 'Editar categoría' : 'Nueva categoría de ${widget.isIncome ? 'Ingreso' : 'Gasto'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.label_outline)), textCapitalization: TextCapitalization.words),
        const SizedBox(height: 14),
        TextField(controller: _iconCtrl, decoration: const InputDecoration(labelText: 'Emoji', hintText: 'Ej: 🍕  🚗  💰', prefixIcon: Icon(Icons.emoji_emotions_outlined)), style: const TextStyle(fontSize: 22), maxLength: 4),
        Row(children: [
          const Text('Color:', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(width: 12),
          GestureDetector(onTap: () => _pickColor(context), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: _color, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 2)))),
          const SizedBox(width: 10),
          TextButton(onPressed: () => _pickColor(context), child: const Text('Personalizar')),
        ]),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            if (_nameCtrl.text.trim().isEmpty) return;
            if (widget.editCat != null) {
              context.read<FinanceProvider>().editCategory(widget.editCat!.id, name: _nameCtrl.text.trim(), icon: _iconCtrl.text.trim().isEmpty ? widget.editCat!.icon : _iconCtrl.text.trim(), colorValue: _color.value);
            } else {
              context.read<FinanceProvider>().addCategory(name: _nameCtrl.text.trim(), colorValue: _color.value, icon: _iconCtrl.text.trim().isEmpty ? (widget.isIncome ? '💰' : '💸') : _iconCtrl.text.trim(), isIncome: widget.isIncome);
            }
            Navigator.pop(context);
          },
          child: Text(widget.editCat != null ? 'Guardar cambios' : 'Guardar categoría'),
        )),
      ]),
    );
  }

  void _pickColor(BuildContext context) => showDialog(context: context, builder: (_) => AlertDialog(
    title: const Text('Elige un color'),
    content: SingleChildScrollView(child: ColorPicker(pickerColor: _color, onColorChanged: (c) => setState(() => _color = c), pickerAreaHeightPercent: 0.7, enableAlpha: false, labelTypes: const [])),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Listo'))],
  ));
}
