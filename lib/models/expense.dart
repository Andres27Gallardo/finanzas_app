class Expense {
  final String type; // ingreso, egreso, transferencia
  final String category;
  final double amount;
  final String description;
  final String account;
  final String? toAccount;
  final DateTime date;

  Expense({
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.account,
    this.toAccount,
    required this.date,
  });
}