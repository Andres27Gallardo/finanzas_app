class Debt {
  final String id;
  String personName, accountId, returnAccountId, notes;
  double totalAmount, paidAmount;
  DateTime startDate;
  DateTime? dueDate;
  int? returnFrequencyDays;
  bool isLent;

  Debt({required this.id, required this.personName, required this.totalAmount, this.paidAmount = 0, required this.accountId, required this.returnAccountId, required this.startDate, this.dueDate, this.returnFrequencyDays, this.notes = '', this.isLent = true});

  double get remaining => totalAmount - paidAmount;
  bool get isCompleted => paidAmount >= totalAmount;
  double get progress => totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0;

  Map<String, dynamic> toMap() => {
    'id': id, 'personName': personName, 'totalAmount': totalAmount,
    'paidAmount': paidAmount, 'accountId': accountId, 'returnAccountId': returnAccountId,
    'startDate': startDate.toIso8601String(), 'dueDate': dueDate?.toIso8601String(),
    'returnFrequencyDays': returnFrequencyDays, 'notes': notes, 'isLent': isLent,
  };

  factory Debt.fromMap(Map<dynamic, dynamic> m) => Debt(
    id: m['id'], personName: m['personName'],
    totalAmount: (m['totalAmount'] as num).toDouble(),
    paidAmount: ((m['paidAmount'] as num?) ?? 0).toDouble(),
    accountId: m['accountId'],
    returnAccountId: (m['returnAccountId'] as String?) ?? '',
    startDate: DateTime.parse(m['startDate']),
    dueDate: m['dueDate'] != null ? DateTime.parse(m['dueDate']) : null,
    returnFrequencyDays: m['returnFrequencyDays'] as int?,
    notes: (m['notes'] as String?) ?? '',
    isLent: (m['isLent'] as bool?) ?? true,
  );
}
