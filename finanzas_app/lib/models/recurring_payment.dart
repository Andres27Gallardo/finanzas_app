class RecurringPayment {
  final String id;
  String name, description, categoryId, accountId, icon;
  double? fixedAmount;
  bool isFixedAmount, isActive, iAmPaying;
  int frequencyDays;
  int? dayOfMonth; // día específico del mes (ej: 5, 15)
  DateTime startDate, nextDueDate;

  RecurringPayment({
    required this.id, required this.name, required this.description,
    required this.categoryId, required this.accountId, required this.icon,
    this.fixedAmount, required this.isFixedAmount, required this.frequencyDays,
    this.dayOfMonth, required this.startDate, required this.nextDueDate,
    this.isActive = true, this.iAmPaying = true,
  });

  bool get isDueToday {
    final now = DateTime.now();
    return nextDueDate.day == now.day && nextDueDate.month == now.month && nextDueDate.year == now.year;
  }
  bool get isOverdue => nextDueDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
  int get daysUntilDue {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return due.difference(today).inDays;
  }
  String get frequencyLabel {
    if (dayOfMonth != null) return 'Día $dayOfMonth de cada mes';
    switch (frequencyDays) {
      case 7: return 'Semanal';
      case 14: return 'Quincenal';
      case 30: return 'Mensual';
      case 60: return 'Bimestral';
      case 90: return 'Trimestral';
      case 180: return 'Semestral';
      case 365: return 'Anual';
      default: return 'Cada $frequencyDays días';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'description': description,
    'categoryId': categoryId, 'accountId': accountId, 'icon': icon,
    'fixedAmount': fixedAmount, 'isFixedAmount': isFixedAmount,
    'frequencyDays': frequencyDays, 'dayOfMonth': dayOfMonth,
    'startDate': startDate.toIso8601String(), 'nextDueDate': nextDueDate.toIso8601String(),
    'isActive': isActive, 'iAmPaying': iAmPaying,
  };

  factory RecurringPayment.fromMap(Map<dynamic, dynamic> m) => RecurringPayment(
    id: m['id'], name: m['name'], description: m['description'] ?? '',
    categoryId: m['categoryId'], accountId: m['accountId'], icon: m['icon'] ?? '🔄',
    fixedAmount: (m['fixedAmount'] as num?)?.toDouble(),
    isFixedAmount: m['isFixedAmount'] as bool,
    frequencyDays: m['frequencyDays'] as int,
    dayOfMonth: m['dayOfMonth'] as int?,
    startDate: DateTime.parse(m['startDate']),
    nextDueDate: DateTime.parse(m['nextDueDate']),
    isActive: (m['isActive'] as bool?) ?? true,
    iAmPaying: (m['iAmPaying'] as bool?) ?? true,
  );
}
