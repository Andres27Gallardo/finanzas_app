class UserProfile {
  final String id;
  String name, email, occupation, mainGoal;
  int age;
  double monthlyIncome, monthlyExpenses;

  UserProfile({required this.id, required this.name, required this.email, this.age = 0, this.occupation = '', this.monthlyIncome = 0, this.monthlyExpenses = 0, this.mainGoal = 'Uso general'});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'email': email, 'age': age, 'occupation': occupation, 'monthlyIncome': monthlyIncome, 'monthlyExpenses': monthlyExpenses, 'mainGoal': mainGoal};

  factory UserProfile.fromMap(Map<dynamic, dynamic> m) => UserProfile(
    id: m['id'], name: m['name'], email: m['email'],
    age: (m['age'] as int?) ?? 0, occupation: (m['occupation'] as String?) ?? '',
    monthlyIncome: ((m['monthlyIncome'] as num?) ?? 0).toDouble(),
    monthlyExpenses: ((m['monthlyExpenses'] as num?) ?? 0).toDouble(),
    mainGoal: (m['mainGoal'] as String?) ?? 'Uso general',
  );
}
