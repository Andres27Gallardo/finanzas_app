import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';
import '../services/gemini_service.dart';
import '../services/permission_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? editTransaction;
  const AddTransactionScreen({super.key, this.editTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _aiCtrl = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  String? _selectedToAccountId;
  DateTime _date = DateTime.now();
  bool _loading = false;
  bool _aiLoading = false;
  bool _isListening = false;

  final SpeechToText _speech = SpeechToText();
  final GeminiService _gemini = GeminiService();

  bool get _isEdit => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    final p = context.read<FinanceProvider>();

    if (_isEdit) {
      final t = widget.editTransaction!;
      _type = t.type;
      _amountCtrl.text = t.amount.toString();
      _descCtrl.text = t.description;
      _selectedCategoryId = t.categoryId;
      _selectedAccountId = t.accountId;
      _selectedToAccountId = t.toAccountId;
      _date = t.date;
    } else {
      if (p.accounts.isNotEmpty) _selectedAccountId = p.accounts.first.id;
      final cats = p.expenseCategories;
      if (cats.isNotEmpty) _selectedCategoryId = cats.first.id;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) PermissionService.requestAll();
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _aiCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  void _onTypeChanged(TransactionType newType) {
    setState(() {
      _type = newType;
      _selectedToAccountId = null;
      final p = context.read<FinanceProvider>();
      if (newType == TransactionType.income) {
        _selectedCategoryId = p.incomeCategories.isNotEmpty
            ? p.incomeCategories.first.id
            : null;
      } else if (newType == TransactionType.expense) {
        _selectedCategoryId = p.expenseCategories.isNotEmpty
            ? p.expenseCategories.first.id
            : null;
      } else {
        _selectedCategoryId = null;
      }
    });
  }

  Future<void> _startListening() async {
    final hasPermission = await PermissionService.requestMicrophone(context);
    if (!hasPermission) return;

    final available = await _speech.initialize(
      onError: (e) => setState(() => _isListening = false),
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Micrófono no disponible'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() => _aiCtrl.text = result.recognizedWords);
        if (result.finalResult) {
          setState(() => _isListening = false);
          if (_aiCtrl.text.isNotEmpty) _analyzeWithAI();
        }
      },
      localeId: 'es_ES',
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _pickImage() async {
    final hasPermission = await PermissionService.requestCamera(context);
    if (!hasPermission) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (picked == null) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📷 Foto tomada. Escribe el monto y presiona IA.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cámara: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _analyzeWithAI() async {
    final text = _aiCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe algo, ej: "gasté 50 en comida"'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _aiLoading = true);
    final result = await _gemini.analyzeTransactionText(text);
    setState(() => _aiLoading = false);

    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ IA no respondió. Verifica tu API Key e internet.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final p = context.read<FinanceProvider>();

    // Tipo
    final tipo = (result['tipo'] as String? ?? '').toLowerCase();
    if (tipo == 'ingreso') {
      _type = TransactionType.income;
    } else {
      _type = TransactionType.expense;
    }

    // Monto
    final monto = result['monto'];
    if (monto != null) {
      _amountCtrl.text = monto.toString();
    }

    // Descripcion
    final desc = result['descripcion'] as String? ?? result['descripción'] as String? ?? '';
    if (desc.isNotEmpty) _descCtrl.text = desc;

    // Categoria
    final catName = (result['categoria'] as String? ?? '').toLowerCase();
    final cats = _type == TransactionType.income ? p.incomeCategories : p.expenseCategories;

    final match = cats.where((c) =>
        c.name.toLowerCase().contains(catName) ||
        catName.contains(c.name.toLowerCase()));

    if (match.isNotEmpty) {
      _selectedCategoryId = match.first.id;
    } else if (cats.isNotEmpty) {
      _selectedCategoryId = cats.first.id;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ IA completó el formulario'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) {
      setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (t != null) {
      setState(() => _date = DateTime(_date.year, _date.month, _date.day, t.hour, t.minute));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar cuenta origen
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una cuenta'), backgroundColor: Colors.red),
      );
      return;
    }

    // Validar cuenta destino para transferencia
    if (_type == TransactionType.transfer) {
      if (_selectedToAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona la cuenta destino para la transferencia'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_selectedToAccountId == _selectedAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La cuenta origen y destino no pueden ser la misma'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _loading = true);
    final p = context.read<FinanceProvider>();

    final cats = _type == TransactionType.income
        ? p.incomeCategories
        : p.expenseCategories;
    final catId = _selectedCategoryId ??
        (cats.isNotEmpty ? cats.first.id : (p.categories.isNotEmpty ? p.categories.first.id : ''));

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;

    try {
      if (_isEdit) {
        await p.editTransaction(
          widget.editTransaction!,
          type: _type,
          amount: amount,
          categoryId: catId,
          description: _descCtrl.text.trim(),
          accountId: _selectedAccountId!,
          date: _date,
        );
      } else {
        await p.addTransaction(
          type: _type,
          amount: amount,
          categoryId: catId,
          description: _descCtrl.text.trim(),
          accountId: _selectedAccountId!,
          toAccountId: _type == TransactionType.transfer ? _selectedToAccountId : null,
          date: _date,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanceProvider>();
    final theme = Theme.of(context);
    final cats = _type == TransactionType.income
        ? p.incomeCategories
        : p.expenseCategories;

    // Para transferencia: cuentas destino = todas menos la cuenta origen
    final toAccounts = p.accounts
        .where((a) => a.id != _selectedAccountId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Editar Transacción' : 'Nueva Transacción',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ─── IA Card ────────────────────────────────────────────────
              Card(
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('🤖', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8),
                          Text('Auto-completar con IA',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Escribe, habla o usa la cámara',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _aiCtrl,
                              decoration: const InputDecoration(
                                hintText: '"gasté 50 en almuerzo"',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              onSubmitted: (_) => _analyzeWithAI(),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _isListening ? _stopListening : _startListening,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: _isListening ? Colors.red : Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isListening ? Icons.stop : Icons.mic,
                                color: Colors.white, size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 42, height: 42,
                              decoration: const BoxDecoration(
                                  color: Colors.blue, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: _aiLoading ? null : _analyzeWithAI,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 11),
                            ),
                            child: _aiLoading
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('IA', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                      if (_isListening)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.mic, color: Colors.red, size: 14),
                              SizedBox(width: 4),
                              Text('Escuchando...',
                                  style: TextStyle(color: Colors.red, fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Tipo ────────────────────────────────────────────────────
              Text('Tipo',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TypeBtn('Ingreso', '📈', Colors.green,
                      _type == TransactionType.income,
                      () => _onTypeChanged(TransactionType.income)),
                  const SizedBox(width: 8),
                  _TypeBtn('Gasto', '📉', Colors.red,
                      _type == TransactionType.expense,
                      () => _onTypeChanged(TransactionType.expense)),
                  const SizedBox(width: 8),
                  _TypeBtn('Transferencia', '🔄', Colors.blue,
                      _type == TransactionType.transfer,
                      () => _onTypeChanged(TransactionType.transfer)),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Monto ───────────────────────────────────────────────────
              TextFormField(
                controller: _amountCtrl,
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixText: '${p.currency} ',
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa un monto';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                    return 'Número inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ─── Descripción ─────────────────────────────────────────────
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Agrega una descripción' : null,
              ),
              const SizedBox(height: 16),

              // ─── Categorías (solo ingreso/gasto) ─────────────────────────
              if (_type != TransactionType.transfer) ...[
                Text('Categoría',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                cats.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '⚠️ Sin categorías. Crea una en Más > Categorías.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: cats.map((c) {
                          final sel = _selectedCategoryId == c.id;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategoryId = c.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel
                                    ? Color(c.colorValue)
                                    : Color(c.colorValue).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: sel
                                    ? null
                                    : Border.all(
                                        color:
                                            Color(c.colorValue).withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(c.icon,
                                      style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Text(
                                    c.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: sel ? Colors.white : null,
                                      fontWeight: sel
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 16),
              ],

              // ─── Cuenta origen ────────────────────────────────────────────
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                decoration: InputDecoration(
                  labelText: _type == TransactionType.transfer
                      ? 'Cuenta origen'
                      : 'Cuenta',
                  prefixIcon:
                      const Icon(Icons.account_balance_wallet_outlined),
                ),
                items: p.accounts
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.icon} ${a.name}'),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedAccountId = v;
                    // Reset cuenta destino si es la misma
                    if (_selectedToAccountId == v) {
                      _selectedToAccountId = null;
                    }
                  });
                },
                validator: (v) => v == null ? 'Selecciona una cuenta' : null,
              ),
              const SizedBox(height: 16),

              // ─── Cuenta destino (solo transferencia) ──────────────────────
              if (_type == TransactionType.transfer) ...[
                DropdownButtonFormField<String>(
                  value: _selectedToAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Cuenta destino',
                    prefixIcon: Icon(Icons.arrow_forward),
                  ),
                  items: toAccounts.isEmpty
                      ? [
                          const DropdownMenuItem(
                            value: null,
                            child: Text(
                                'Necesitas al menos 2 cuentas',
                                style: TextStyle(color: Colors.grey)),
                          )
                        ]
                      : toAccounts
                          .map((a) => DropdownMenuItem(
                                value: a.id,
                                child: Text('${a.icon} ${a.name}'),
                              ))
                          .toList(),
                  onChanged: toAccounts.isEmpty
                      ? null
                      : (v) => setState(() => _selectedToAccountId = v),
                  validator: (v) {
                    if (_type == TransactionType.transfer && v == null) {
                      return 'Selecciona la cuenta destino';
                    }
                    return null;
                  },
                ),
                if (toAccounts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Para transferir necesitas al menos 2 cuentas. Crea una nueva en la pestaña Cuentas.',
                              style: TextStyle(
                                  color: Colors.orange, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // ─── Fecha y Hora ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_date),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hora',
                          prefixIcon: Icon(Icons.access_time_outlined),
                        ),
                        child: Text(
                          DateFormat('HH:mm').format(_date),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ─── Botón guardar ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(_isEdit ? 'Guardar cambios' : 'Guardar'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label, icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeBtn(this.label, this.icon, this.color, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? color : color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
