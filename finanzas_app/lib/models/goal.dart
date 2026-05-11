class Goal {
  final String id;
  String name, icon, accountId;
  double targetAmount;
  DateTime? deadline;

  Goal({
    required this.id,
    required this.name,
    required this.icon,
    required this.targetAmount,
    required this.accountId,
    this.deadline,
  });

  // ✅ Estos getters los calcula el provider usando el saldo real de la cuenta
  // Se mantienen aquí para compatibilidad con goals_screen.dart
  double savedAmount = 0; // Se actualiza desde provider
  double get remaining => targetAmount - savedAmount;
  bool get isCompleted => savedAmount >= targetAmount;
  double get progress => targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0;

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'icon': icon,
    'targetAmount': targetAmount, 'accountId': accountId,
    'deadline': deadline?.toIso8601String(),
  };

  factory Goal.fromMap(Map<dynamic, dynamic> m) => Goal(
    id: m['id'], name: m['name'], icon: m['icon'],
    targetAmount: (m['targetAmount'] as num).toDouble(),
    accountId: m['accountId'],
    deadline: m['deadline'] != null ? DateTime.parse(m['deadline']) : null,
  );
}
