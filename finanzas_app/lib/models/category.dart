class CategoryModel {
  final String id;
  String name, icon;
  int colorValue;
  bool isIncome;

  CategoryModel({required this.id, required this.name, required this.colorValue, required this.icon, required this.isIncome});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'colorValue': colorValue, 'icon': icon, 'isIncome': isIncome};

  factory CategoryModel.fromMap(Map<dynamic, dynamic> m) => CategoryModel(
    id: m['id'], name: m['name'], colorValue: m['colorValue'], icon: m['icon'], isIncome: m['isIncome'],
  );
}
