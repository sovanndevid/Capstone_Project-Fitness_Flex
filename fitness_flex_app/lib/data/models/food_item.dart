class FoodItem {
  final String id;
  final String name;
  final String brand;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final int servingSize; // in grams
  final String servingUnit;

  FoodItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.servingUnit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      brand: map['brand'],
      calories: map['calories'],
      protein: map['protein'],
      carbs: map['carbs'],
      fat: map['fat'],
      servingSize: map['servingSize'],
      servingUnit: map['servingUnit'],
    );
  }
}


extension FoodItemUSDA on FoodItem {
  static FoodItem fromUSDAJson(Map<String, dynamic> json) {
    final nutrients = json['foodNutrients'] as List? ?? [];

    double getNutrient(String name) {
      final nutrient = nutrients.firstWhere(
        (n) => n['nutrientName'].toString().toLowerCase() == name.toLowerCase(),
        orElse: () => {"value": 0},
      );
      return (nutrient['value'] as num?)?.toDouble() ?? 0.0;
    }

    return FoodItem(
      id: json['fdcId'].toString(),
      name: json['description'] ?? "Unknown",
      brand: json['brandOwner'] ?? "Generic",
      calories: getNutrient("Energy"),
      protein: getNutrient("Protein"),
      carbs: getNutrient("Carbohydrate, by difference"),
      fat: getNutrient("Total lipid (fat)"),
      servingSize: (json['servingSize'] as num?)?.toInt() ?? 100,
      servingUnit: json['servingSizeUnit'] ?? "g",
    );
  }
}
