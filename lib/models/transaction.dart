class TransactionModel {
  final double amount;
  final String category;
  final String description;
  final String account;
  final DateTime date;
  final bool isIncome;

  TransactionModel({
    required this.amount,
    required this.category,
    required this.description,
    required this.account,
    required this.date,
    required this.isIncome,
  });
}