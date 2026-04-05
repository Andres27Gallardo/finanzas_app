class Expense {
  final String category;
  final double amount;
  final String type; // ingreso / egreso
  final String description;
  final DateTime date;
  final String account;

  Expense({
    required this.category,
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
    required this.account,
  });
}