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
  final String source;   // 

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
    required this.source,
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
      'source': source,
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
      source: map['source'],
    );
  }
}

///  USDA Adapter
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
      source: "USDA",
    );
  }
}

///  AUSNUT Adapter
extension FoodItemAUSNUT on FoodItem {
  /// For search results (no nutrients, just description + category)
  static FoodItem fromAUSNUTSearchJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['fdcId'].toString(),
      name: json['description'] ?? "Unknown",
      brand: "AUSNUT",
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      servingSize: 100,
      servingUnit: "g",
      source: "AUSNUT",
    );
  }

  /// For detailed food info (includes nutrients)
  static FoodItem fromAUSNUTDetailJson(Map<String, dynamic> json) {
    final nutrients = json['foodNutrients'] as List? ?? [];

    double getNutrient(String name) {
      final nutrient = nutrients.firstWhere(
        (n) =>
            n['nutrientName'].toString().toLowerCase() == name.toLowerCase(),
        orElse: () => {"value": 0},
      );
      return (nutrient['value'] as num?)?.toDouble() ?? 0.0;
    }

    return FoodItem(
      id: json['fdcId'].toString(),
      name: json['description'] ?? "Unknown",
      brand: "AUSNUT",
      calories: getNutrient("Energy without dietary fibre"),
      protein: getNutrient("Protein"),
      carbs: getNutrient("Available carbohydrate, without sugar alcohols"),
      fat: getNutrient("Total fat"),
      servingSize: 100,
      servingUnit: "g",
      source: "AUSNUT",
    );
  }
}
