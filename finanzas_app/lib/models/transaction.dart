enum TransactionType { income, expense, transfer }

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId, description, accountId;
  final String? toAccountId;
  final DateTime date, createdAt;

  Transaction({required this.id, required this.type, required this.amount, required this.categoryId, required this.description, required this.accountId, this.toAccountId, required this.date, required this.createdAt});

  Map<String, dynamic> toMap() => {
    'id': id, 'type': type.index, 'amount': amount,
    'categoryId': categoryId, 'description': description,
    'accountId': accountId, 'toAccountId': toAccountId,
    'date': date.toIso8601String(), 'createdAt': createdAt.toIso8601String(),
  };

  factory Transaction.fromMap(Map<dynamic, dynamic> m) => Transaction(
    id: m['id'], type: TransactionType.values[m['type']],
    amount: (m['amount'] as num).toDouble(),
    categoryId: m['categoryId'], description: m['description'],
    accountId: m['accountId'], toAccountId: m['toAccountId'],
    date: DateTime.parse(m['date']), createdAt: DateTime.parse(m['createdAt']),
  );
}
