class NutritionGoal {
  final double dailyCalories;
  final double dailyProtein;
  final double dailyCarbs;
  final double dailyFat;
  final double dailyWater;

  NutritionGoal({
    required this.dailyCalories,
    required this.dailyProtein,
    required this.dailyCarbs,
    required this.dailyFat,
    required this.dailyWater,
  });

  Map<String, dynamic> toMap() {
    return {
      'dailyCalories': dailyCalories,
      'dailyProtein': dailyProtein,
      'dailyCarbs': dailyCarbs,
      'dailyFat': dailyFat,
      'dailyWater': dailyWater,
    };
  }

  factory NutritionGoal.fromMap(Map<String, dynamic> map) {
    return NutritionGoal(
      dailyCalories: map['dailyCalories'],
      dailyProtein: map['dailyProtein'],
      dailyCarbs: map['dailyCarbs'],
      dailyFat: map['dailyFat'],
      dailyWater: map['dailyWater'],
    );
  }
}
