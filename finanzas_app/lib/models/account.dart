class Account {
  final String id;
  String name, icon;
  double balance;
  int colorValue;
  bool includeInBalance;

  Account({required this.id, required this.name, required this.balance, required this.colorValue, this.icon = '🏦', this.includeInBalance = true});

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'balance': balance,
    'colorValue': colorValue, 'icon': icon, 'includeInBalance': includeInBalance,
  };

  factory Account.fromMap(Map<dynamic, dynamic> m) => Account(
    id: m['id'], name: m['name'],
    balance: (m['balance'] as num).toDouble(),
    colorValue: m['colorValue'],
    icon: (m['icon'] as String?) ?? '🏦',
    includeInBalance: (m['includeInBalance'] as bool?) ?? true,
  );
}
