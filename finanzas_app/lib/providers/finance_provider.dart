import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/user_profile.dart';
import '../models/goal.dart';
import '../models/debt.dart';
import '../models/recurring_payment.dart';
import '../services/notification_service.dart';
import '../services/gemini_service.dart';

class FinanceProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  final _notif = NotificationService();
  final _gemini = GeminiService();

  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  List<CategoryModel> _categories = [];
  List<Goal> _goals = [];
  List<Debt> _debts = [];
  List<RecurringPayment> _recurringPayments = [];
  UserProfile? _userProfile;
  bool _isLoggedIn = false, _isDarkMode = false, _isProfileComplete = false;
  String _currency = 'Bs', _dashboardPeriod = 'month';

  late Box _txBox, _accBox, _catBox, _userBox, _settingsBox, _goalBox, _debtBox, _recurringBox;

  List<Transaction> get transactions => _transactions;
  List<Account> get accounts => _accounts;
  List<CategoryModel> get categories => _categories;
  List<Goal> get goals => _goals;
  List<Debt> get debts => _debts;
  List<RecurringPayment> get recurringPayments => _recurringPayments;
  UserProfile? get userProfile => _userProfile;
  bool get isLoggedIn => _isLoggedIn;
  bool get isDarkMode => _isDarkMode;
  bool get isProfileComplete => _isProfileComplete;
  String get currency => _currency;
  String get dashboardPeriod => _dashboardPeriod;
  GeminiService get gemini => _gemini;

  List<CategoryModel> get incomeCategories => _categories.where((c) => c.isIncome).toList();
  List<CategoryModel> get expenseCategories => _categories.where((c) => !c.isIncome).toList();

  double get totalBalance => _accounts.where((a) => a.includeInBalance).fold(0, (s, a) => s + a.balance);
  double get periodIncome => _getPeriodTx(TransactionType.income).fold(0, (s, t) => s + t.amount);
  double get periodExpenses => _getPeriodTx(TransactionType.expense).fold(0, (s, t) => s + t.amount);
  double get monthlyIncome => periodIncome;
  double get monthlyExpenses => periodExpenses;

  String get periodLabel {
    switch (_dashboardPeriod) {
      case 'day': return 'hoy';
      case 'week': return 'esta semana';
      case 'year': return 'este año';
      default: return 'este mes';
    }
  }

  List<Transaction> _getPeriodTx(TransactionType type) {
    final now = DateTime.now();
    return _transactions.where((t) {
      if (t.type != type) return false;
      switch (_dashboardPeriod) {
        case 'day': return t.date.day == now.day && t.date.month == now.month && t.date.year == now.year;
        case 'week': return t.date.isAfter(now.subtract(const Duration(days: 7)));
        case 'year': return t.date.year == now.year;
        default: return t.date.month == now.month && t.date.year == now.year;
      }
    }).toList();
  }

  List<Transaction> get recentTransactions {
    final s = [..._transactions]..sort((a, b) => b.date.compareTo(a.date));
    return s.take(50).toList();
  }

  String get financialHealth {
    if (periodIncome == 0) return 'neutral';
    final r = periodExpenses / periodIncome;
    if (r < 0.5) return 'good';
    if (r < 0.8) return 'medium';
    return 'bad';
  }

  double getAccountBalance(String accountId) {
    try { return _accounts.firstWhere((a) => a.id == accountId).balance; }
    catch (_) { return 0; }
  }

  Future<void> init() async {
    _txBox = Hive.box('transactions');
    _accBox = Hive.box('accounts');
    _catBox = Hive.box('categories');
    _userBox = Hive.box('user_data');
    _settingsBox = Hive.box('settings');
    _goalBox = Hive.box('goals');
    _debtBox = Hive.box('debts');
    _recurringBox = Hive.box('recurring_payments');
    _loadData();
    await _notif.init();
  }

  void _loadData() {
    _isDarkMode = _settingsBox.get('darkMode', defaultValue: false) as bool;
    _currency = _settingsBox.get('currency', defaultValue: 'Bs') as String;
    _dashboardPeriod = _settingsBox.get('dashboardPeriod', defaultValue: 'month') as String;
    final u = _userBox.get('current_user');
    if (u != null) {
      _userProfile = UserProfile.fromMap(u as Map);
      _isLoggedIn = true;
      _isProfileComplete = _userBox.get('profile_complete', defaultValue: false) as bool;
    }
    _accounts = _accBox.values.map((e) => Account.fromMap(e as Map)).toList();
    _categories = _catBox.values.map((e) => CategoryModel.fromMap(e as Map)).toList();
    _transactions = _txBox.values.map((e) => Transaction.fromMap(e as Map)).toList();
    _goals = _goalBox.values.map((e) => Goal.fromMap(e as Map)).toList();
    _debts = _debtBox.values.map((e) => Debt.fromMap(e as Map)).toList();
    _recurringPayments = _recurringBox.values.map((e) => RecurringPayment.fromMap(e as Map)).toList();
    if (_categories.isEmpty) _createDefaultCategories();
    if (_accounts.isEmpty) _createDefaultAccount();
    notifyListeners();
    // ✅ Solo notificaciones — SIN llamadas a IA al inicio
    Future.delayed(const Duration(seconds: 3), _scheduleNotificationsOnly);
  }

  // ✅ No llama a IA aquí — evita quota al abrir app
  Future<void> _scheduleNotificationsOnly() async {
    await _notif.scheduleDailySummary(
      income: '$_currency ${periodIncome.toStringAsFixed(2)}',
      expense: '$_currency ${periodExpenses.toStringAsFixed(2)}',
      balance: '$_currency ${totalBalance.toStringAsFixed(2)}',
      tip: 'Revisa tus gastos del día 💡',
    );
    for (final d in _debts) {
      if (!d.isCompleted && d.dueDate != null) {
        await _notif.scheduleDebtReminder(
          notifId: d.id.hashCode, personName: d.personName,
          amount: '$_currency ${d.remaining.toStringAsFixed(2)}',
          dueDate: d.dueDate!, frequencyDays: d.returnFrequencyDays,
        );
      }
    }
    for (final r in _recurringPayments) {
      if (r.isActive) await _scheduleRecurringNotification(r);
    }
  }

  void _createDefaultCategories() {
    final defs = [
      {'n':'Comida','i':'🍕','c':0xFFEF5350,'inc':false},
      {'n':'Transporte','i':'🚗','c':0xFF42A5F5,'inc':false},
      {'n':'Entretenimiento','i':'🎮','c':0xFF7E57C2,'inc':false},
      {'n':'Salud','i':'💊','c':0xFF26A69A,'inc':false},
      {'n':'Ropa','i':'👕','c':0xFFEC407A,'inc':false},
      {'n':'Educación','i':'📚','c':0xFF5C6BC0,'inc':false},
      {'n':'Hogar','i':'🏠','c':0xFFFF7043,'inc':false},
      {'n':'Servicios','i':'💡','c':0xFFFFA726,'inc':false},
      {'n':'Otros gastos','i':'💸','c':0xFF78909C,'inc':false},
      {'n':'Salario','i':'💼','c':0xFF66BB6A,'inc':true},
      {'n':'Freelance','i':'💻','c':0xFF26C6DA,'inc':true},
      {'n':'Inversiones','i':'📈','c':0xFFFFCA28,'inc':true},
      {'n':'Regalos','i':'🎁','c':0xFFAB47BC,'inc':true},
      {'n':'Otros ingresos','i':'💰','c':0xFF9CCC65,'inc':true},
    ];
    for (final d in defs) {
      final c = CategoryModel(id: _uuid.v4(), name: d['n'] as String, colorValue: d['c'] as int, icon: d['i'] as String, isIncome: d['inc'] as bool);
      _catBox.put(c.id, c.toMap()); _categories.add(c);
    }
  }

  void _createDefaultAccount() {
    final a = Account(id: _uuid.v4(), name: 'Cuenta Principal', balance: 0, colorValue: 0xFF6C63FF, icon: '🏦', includeInBalance: true);
    _accBox.put(a.id, a.toMap()); _accounts.add(a);
  }

  Future<bool> login(String email, String password) async {
    final s = _userBox.get('auth_$email');
    if (s != null && (s as Map)['password'] == password) {
      _userProfile = UserProfile.fromMap(s['profile'] as Map);
      _isLoggedIn = true;
      _isProfileComplete = _userBox.get('profile_complete', defaultValue: false) as bool;
      await _userBox.put('current_user', s['profile']);
      notifyListeners(); return true;
    }
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    if (_userBox.containsKey('auth_$email')) return false;
    final p = UserProfile(id: _uuid.v4(), name: name, email: email);
    await _userBox.put('auth_$email', {'password': password, 'profile': p.toMap()});
    await _userBox.put('current_user', p.toMap());
    _userProfile = p; _isLoggedIn = true; _isProfileComplete = false;
    notifyListeners(); return true;
  }

  Future<bool> changePassword(String email, String newPassword) async {
    final s = _userBox.get('auth_$email');
    if (s == null) return false;
    await _userBox.put('auth_$email', {'password': newPassword, 'profile': (s as Map)['profile']});
    return true;
  }

  Future<void> completeProfile({required int age, required String occupation, required double monthlyIncome, required double monthlyExpenses, required String mainGoal}) async {
    if (_userProfile == null) return;
    _userProfile!.age = age; _userProfile!.occupation = occupation;
    _userProfile!.monthlyIncome = monthlyIncome; _userProfile!.monthlyExpenses = monthlyExpenses;
    _userProfile!.mainGoal = mainGoal;
    final a = (_userBox.get('auth_${_userProfile!.email}') as Map?) ?? {};
    await _userBox.put('auth_${_userProfile!.email}', {'password': a['password'], 'profile': _userProfile!.toMap()});
    await _userBox.put('current_user', _userProfile!.toMap());
    await _userBox.put('profile_complete', true);
    _isProfileComplete = true; notifyListeners();
  }

  Future<void> logout() async {
    await _userBox.delete('current_user');
    await _notif.cancelAll();
    _userProfile = null; _isLoggedIn = false; _isProfileComplete = false;
    notifyListeners();
  }

  Future<void> setCurrency(String s) async { _currency = s; await _settingsBox.put('currency', s); notifyListeners(); }
  void toggleDarkMode() { _isDarkMode = !_isDarkMode; _settingsBox.put('darkMode', _isDarkMode); notifyListeners(); }
  Future<void> setDashboardPeriod(String p) async { _dashboardPeriod = p; await _settingsBox.put('dashboardPeriod', p); notifyListeners(); }

  Future<void> addTransaction({required TransactionType type, required double amount, required String categoryId, required String description, required String accountId, String? toAccountId, required DateTime date}) async {
    final t = Transaction(id: _uuid.v4(), type: type, amount: amount, categoryId: categoryId, description: description, accountId: accountId, toAccountId: toAccountId, date: date, createdAt: DateTime.now());
    final acc = _accounts.firstWhere((a) => a.id == accountId);
    if (type == TransactionType.income) { acc.balance += amount; }
    else if (type == TransactionType.expense) { acc.balance -= amount; }
    else if (type == TransactionType.transfer && toAccountId != null) {
      acc.balance -= amount;
      final to = _accounts.firstWhere((a) => a.id == toAccountId);
      to.balance += amount;
      await _accBox.put(toAccountId, to.toMap());
    }
    await _accBox.put(accountId, acc.toMap());
    await _txBox.put(t.id, t.toMap());
    _transactions.add(t); notifyListeners();
  }

  Future<void> editTransaction(Transaction old, {required TransactionType type, required double amount, required String categoryId, required String description, required String accountId, required DateTime date}) async {
    await deleteTransaction(old.id);
    await addTransaction(type: type, amount: amount, categoryId: categoryId, description: description, accountId: accountId, date: date);
  }

  Future<void> deleteTransaction(String id) async {
    final t = _transactions.firstWhere((t) => t.id == id);
    final acc = _accounts.firstWhere((a) => a.id == t.accountId);
    if (t.type == TransactionType.income) { acc.balance -= t.amount; }
    else if (t.type == TransactionType.expense) { acc.balance += t.amount; }
    else if (t.type == TransactionType.transfer && t.toAccountId != null) {
      acc.balance += t.amount;
      try { final to = _accounts.firstWhere((a) => a.id == t.toAccountId); to.balance -= t.amount; await _accBox.put(t.toAccountId!, to.toMap()); } catch (_) {}
    }
    await _accBox.put(acc.id, acc.toMap());
    await _txBox.delete(id);
    _transactions.removeWhere((tx) => tx.id == id);
    notifyListeners();
  }

  Future<void> addAccount({required String name, required double initialBalance, required int colorValue, required String icon, bool includeInBalance = true}) async {
    final a = Account(id: _uuid.v4(), name: name, balance: initialBalance, colorValue: colorValue, icon: icon, includeInBalance: includeInBalance);
    await _accBox.put(a.id, a.toMap()); _accounts.add(a); notifyListeners();
  }

  Future<void> editAccount(String id, {required String name, required String icon, required int colorValue}) async {
    final a = _accounts.firstWhere((a) => a.id == id);
    a.name = name; a.icon = icon; a.colorValue = colorValue;
    await _accBox.put(id, a.toMap()); notifyListeners();
  }

  Future<void> toggleAccountInBalance(String id) async {
    final a = _accounts.firstWhere((a) => a.id == id);
    a.includeInBalance = !a.includeInBalance;
    await _accBox.put(id, a.toMap()); notifyListeners();
  }

  Future<void> deleteAccount(String id) async {
    final txToDelete = _transactions.where((t) => t.accountId == id || t.toAccountId == id).map((t) => t.id).toList();
    for (final tid in txToDelete) { await _txBox.delete(tid); }
    _transactions.removeWhere((t) => t.accountId == id || t.toAccountId == id);
    final debtsToDel = _debts.where((d) => d.accountId == id || d.returnAccountId == id).map((d) => d.id).toList();
    for (final did in debtsToDel) { await _debtBox.delete(did); }
    _debts.removeWhere((d) => d.accountId == id || d.returnAccountId == id);
    final goalsToDel = _goals.where((g) => g.accountId == id).map((g) => g.id).toList();
    for (final gid in goalsToDel) { await _goalBox.delete(gid); }
    _goals.removeWhere((g) => g.accountId == id);
    await _accBox.delete(id); _accounts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Future<void> addCategory({required String name, required int colorValue, required String icon, required bool isIncome}) async {
    final c = CategoryModel(id: _uuid.v4(), name: name, colorValue: colorValue, icon: icon, isIncome: isIncome);
    await _catBox.put(c.id, c.toMap()); _categories.add(c); notifyListeners();
  }

  Future<void> editCategory(String id, {required String name, required String icon, required int colorValue}) async {
    final cat = _categories.firstWhere((c) => c.id == id);
    cat.name = name; cat.icon = icon; cat.colorValue = colorValue;
    await _catBox.put(id, cat.toMap()); notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    final txToDelete = _transactions.where((t) => t.categoryId == id).map((t) => t.id).toList();
    for (final tid in txToDelete) { await _txBox.delete(tid); }
    _transactions.removeWhere((t) => t.categoryId == id);
    await _catBox.delete(id); _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<void> addGoal({required String name, required String icon, required double targetAmount, required String accountId, DateTime? deadline}) async {
    final g = Goal(id: _uuid.v4(), name: name, icon: icon, targetAmount: targetAmount, accountId: accountId, deadline: deadline);
    await _goalBox.put(g.id, g.toMap()); _goals.add(g); notifyListeners();
  }

  Future<void> deleteGoal(String id) async {
    await _goalBox.delete(id); _goals.removeWhere((g) => g.id == id); notifyListeners();
  }

  Future<void> addDebt({required String personName, required double totalAmount, required String accountId, required String returnAccountId, required DateTime startDate, DateTime? dueDate, int? returnFrequencyDays, String notes = '', bool isLent = true}) async {
    final d = Debt(id: _uuid.v4(), personName: personName, totalAmount: totalAmount, accountId: accountId, returnAccountId: returnAccountId, startDate: startDate, dueDate: dueDate, returnFrequencyDays: returnFrequencyDays, notes: notes, isLent: isLent);
    if (isLent) {
      final acc = _accounts.firstWhere((a) => a.id == accountId);
      acc.balance -= totalAmount;
      await _accBox.put(accountId, acc.toMap());
    }
    await _debtBox.put(d.id, d.toMap()); _debts.add(d); notifyListeners();
    if (dueDate != null) {
      await _notif.scheduleDebtReminder(notifId: d.id.hashCode, personName: personName, amount: '$_currency ${totalAmount.toStringAsFixed(2)}', dueDate: dueDate, frequencyDays: returnFrequencyDays);
    }
  }

  Future<void> addDebtPayment(String debtId, double amount) async {
    final d = _debts.firstWhere((d) => d.id == debtId);
    final prevPaid = d.paidAmount;
    d.paidAmount = (d.paidAmount + amount).clamp(0, d.totalAmount);
    final actualAmount = d.paidAmount - prevPaid;
    try { final retAcc = _accounts.firstWhere((a) => a.id == d.returnAccountId); retAcc.balance += actualAmount; await _accBox.put(d.returnAccountId, retAcc.toMap()); } catch (_) {}
    await _debtBox.put(debtId, d.toMap()); notifyListeners();
  }

  Future<void> deleteDebt(String id) async {
    final d = _debts.firstWhere((d) => d.id == id);
    if (d.isLent && !d.isCompleted) {
      try { final acc = _accounts.firstWhere((a) => a.id == d.accountId); acc.balance += d.remaining; await _accBox.put(d.accountId, acc.toMap()); } catch (_) {}
    }
    await _notif.cancel(d.id.hashCode); await _notif.cancel(d.id.hashCode + 1); await _notif.cancel(d.id.hashCode + 2);
    await _debtBox.delete(id); _debts.removeWhere((d) => d.id == id); notifyListeners();
  }

  Future<void> addRecurringPayment({required String name, required String description, required String icon, double? fixedAmount, required bool isFixedAmount, required int frequencyDays, int? dayOfMonth, required String categoryId, required String accountId, required DateTime nextDueDate, required bool iAmPaying}) async {
    final r = RecurringPayment(id: _uuid.v4(), name: name, description: description, icon: icon, fixedAmount: fixedAmount, isFixedAmount: isFixedAmount, frequencyDays: frequencyDays, dayOfMonth: dayOfMonth, categoryId: categoryId, accountId: accountId, startDate: DateTime.now(), nextDueDate: nextDueDate, iAmPaying: iAmPaying);
    await _recurringBox.put(r.id, r.toMap()); _recurringPayments.add(r); notifyListeners();
    await _scheduleRecurringNotification(r);
  }

  Future<void> editRecurringPayment(String id, {required String name, required String description, required String icon, double? fixedAmount, required bool isFixedAmount, required int frequencyDays, int? dayOfMonth, required String categoryId, required String accountId, required DateTime nextDueDate, required bool iAmPaying}) async {
    final r = _recurringPayments.firstWhere((r) => r.id == id);
    r.name = name; r.description = description; r.icon = icon; r.fixedAmount = fixedAmount;
    r.isFixedAmount = isFixedAmount; r.frequencyDays = frequencyDays; r.dayOfMonth = dayOfMonth;
    r.categoryId = categoryId; r.accountId = accountId; r.nextDueDate = nextDueDate; r.iAmPaying = iAmPaying;
    await _recurringBox.put(id, r.toMap()); notifyListeners();
    await _scheduleRecurringNotification(r);
  }

  Future<void> toggleRecurringPayment(String id) async {
    final r = _recurringPayments.firstWhere((r) => r.id == id);
    r.isActive = !r.isActive;
    await _recurringBox.put(id, r.toMap());
    if (!r.isActive) { await _notif.cancel(r.id.hashCode); await _notif.cancel(r.id.hashCode + 1); }
    else { await _scheduleRecurringNotification(r); }
    notifyListeners();
  }

  Future<void> registerRecurringPayment(String id, double amount) async {
    final r = _recurringPayments.firstWhere((r) => r.id == id);
    final type = r.iAmPaying ? TransactionType.expense : TransactionType.income;
    await addTransaction(type: type, amount: amount, categoryId: r.categoryId, description: r.name, accountId: r.accountId, date: DateTime.now());
    // Calcular próximo vencimiento
    if (r.dayOfMonth != null) {
      final now = DateTime.now();
      var next = DateTime(now.year, now.month + 1, r.dayOfMonth!);
      r.nextDueDate = next;
    } else {
      r.nextDueDate = r.nextDueDate.add(Duration(days: r.frequencyDays));
    }
    await _recurringBox.put(id, r.toMap()); notifyListeners();
    await _scheduleRecurringNotification(r);
  }

  Future<void> deleteRecurringPayment(String id) async {
    await _notif.cancel(id.hashCode); await _notif.cancel(id.hashCode + 1);
    await _recurringBox.delete(id); _recurringPayments.removeWhere((r) => r.id == id); notifyListeners();
  }

  Future<void> _scheduleRecurringNotification(RecurringPayment r) async {
    if (!r.isActive) return;
    await _notif.cancel(r.id.hashCode); await _notif.cancel(r.id.hashCode + 1);
    final amountText = r.isFixedAmount && r.fixedAmount != null ? '$_currency${r.fixedAmount!.toStringAsFixed(2)}' : 'monto variable';
    final action = r.iAmPaying ? 'Pagar' : 'Cobrar';
    await _notif.scheduleOnDate(id: r.id.hashCode, title: '💳 $action mañana: ${r.name}', body: 'Mañana: $amountText', dateTime: r.nextDueDate.subtract(const Duration(days: 1)));
    await _notif.scheduleOnDate(id: r.id.hashCode + 1, title: '🔔 ¡$action hoy!: ${r.name}', body: 'Hoy: $amountText', dateTime: r.nextDueDate);
  }

  Future<void> resetAllData() async {
    await _txBox.clear(); await _accBox.clear(); await _catBox.clear();
    await _goalBox.clear(); await _debtBox.clear(); await _recurringBox.clear();
    _transactions = []; _accounts = []; _categories = []; _goals = []; _debts = []; _recurringPayments = [];
    _createDefaultCategories(); _createDefaultAccount();
    await _notif.cancelAll(); notifyListeners();
  }

  List<Transaction> getFilteredTransactions({String filter = 'month', TransactionType? type, DateTime? from, DateTime? to}) {
    final now = DateTime.now();
    return _transactions.where((t) {
      bool ok;
      if (from != null && to != null) {
        ok = !t.date.isBefore(DateTime(from.year, from.month, from.day)) && !t.date.isAfter(DateTime(to.year, to.month, to.day, 23, 59, 59));
      } else {
        switch (filter) {
          case 'day': ok = t.date.day == now.day && t.date.month == now.month && t.date.year == now.year; break;
          case 'week': ok = t.date.isAfter(now.subtract(const Duration(days: 7))); break;
          case 'year': ok = t.date.year == now.year; break;
          default: ok = t.date.month == now.month && t.date.year == now.year;
        }
      }
      return type == null ? ok : ok && t.type == type;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, double> getCategorySpending(String filter) {
    final filtered = getFilteredTransactions(filter: filter, type: TransactionType.expense);
    final Map<String, double> s = {};
    for (final t in filtered) { s[t.categoryId] = (s[t.categoryId] ?? 0) + t.amount; }
    return s;
  }

  CategoryModel? getCategoryById(String id) { try { return _categories.firstWhere((c) => c.id == id); } catch (_) { return null; } }
  Account? getAccountById(String id) { try { return _accounts.firstWhere((a) => a.id == id); } catch (_) { return null; } }

  String get financialSummaryForAI {
    final spending = getCategorySpending(_dashboardPeriod);
    final sorted = spending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topCats = sorted.take(5).map((e) { final c = getCategoryById(e.key); return '- ${c?.icon ?? ''} ${c?.name ?? 'Otro'}: $_currency${e.value.toStringAsFixed(2)}'; }).join('\n');
    return 'Perfil: ${_userProfile?.name ?? ''}, ${_userProfile?.age ?? 0}a, objetivo: ${_userProfile?.mainGoal ?? ''}\n'
        'Período: $_dashboardPeriod | Moneda: $_currency\n'
        'Balance: $_currency${totalBalance.toStringAsFixed(2)}\n'
        'Ingresos ($periodLabel): $_currency${periodIncome.toStringAsFixed(2)}\n'
        'Gastos ($periodLabel): $_currency${periodExpenses.toStringAsFixed(2)}\n'
        'Salud: $financialHealth\n'
        'Top gastos:\n$topCats';
  }
}
