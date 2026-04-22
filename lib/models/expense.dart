class Expense {
  final double amount;
  final String category;
  final String description;
  final String type; // ingreso, egreso, transferencia
  final String account;
  final String? toAccount;
  final DateTime date;

  Expense({
    required this.amount,
    required this.category,
    required this.description,
    required this.type,
    required this.account,
    this.toAccount,
    required this.date,
  });
}