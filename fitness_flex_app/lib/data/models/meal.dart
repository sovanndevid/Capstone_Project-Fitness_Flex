class Meal {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime date;
  final String mealType; // breakfast, lunch, dinner, snack
  final int servingSize;

  Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.date,
    required this.mealType,
    required this.servingSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'date': date.toIso8601String(),
      'mealType': mealType,
      'servingSize': servingSize,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      calories: map['calories'],
      protein: map['protein'],
      carbs: map['carbs'],
      fat: map['fat'],
      date: DateTime.parse(map['date']),
      mealType: map['mealType'],
      servingSize: map['servingSize'],
    );
  }
}
