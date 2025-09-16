import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:fitness_flex_app/data/models/meal.dart';
import 'package:fitness_flex_app/data/models/water_intake.dart';
import 'package:fitness_flex_app/data/models/nutrition_goal.dart';
import 'package:fitness_flex_app/data/models/food_item.dart';

/// Extension to map USDA API results into FoodItem
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

class NutritionRepository {
  static const String _usdaApiKey = "Akb8A33VjAPLOBkB6qcaC4tzBBhStuHK7xum8jb8"; 
  static const String _baseUrl =
      "https://api.nal.usda.gov/fdc/v1/foods/search";

  final List<Meal> _meals = [];
  final List<WaterIntake> _waterIntakes = [];
  NutritionGoal _nutritionGoal = NutritionGoal(
    dailyCalories: 2000,
    dailyProtein: 150,
    dailyCarbs: 250,
    dailyFat: 70,
    dailyWater: 2.5,
  );

  /// 🔹 Search foods using USDA API
  Future<List<FoodItem>> searchFood(String query) async {
    if (query.isEmpty) return [];

    final response = await http.get(
      Uri.parse("$_baseUrl?query=$query&pageSize=10&api_key=$_usdaApiKey"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final foods = data['foods'] as List? ?? [];
      return foods.map((f) => FoodItemUSDA.fromUSDAJson(f)).toList();
    } else {
      throw Exception("USDA API error: ${response.statusCode}");
    }
  }

  /// 🔹 Add meal (local, in-memory for now)
  Future<void> addMeal(Meal meal) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _meals.add(meal);
  }

  /// 🔹 Get today's meals
  Future<List<Meal>> getTodayMeals() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final today = DateTime.now();
    return _meals
        .where(
          (meal) =>
              meal.date.year == today.year &&
              meal.date.month == today.month &&
              meal.date.day == today.day,
        )
        .toList();
  }

  /// 🔹 Water intake tracking
  Future<List<WaterIntake>> getTodayWaterIntakes() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final today = DateTime.now();
    return _waterIntakes
        .where(
          (water) =>
              water.date.year == today.year &&
              water.date.month == today.month &&
              water.date.day == today.day,
        )
        .toList();
  }

  Future<void> addWaterIntake(WaterIntake waterIntake) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _waterIntakes.add(waterIntake);
  }

  /// 🔹 Nutrition goals
  Future<NutritionGoal> getNutritionGoal() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _nutritionGoal;
  }

  Future<void> updateNutritionGoal(NutritionGoal goal) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _nutritionGoal = goal;
  }

  /// 🔹 Nutrition summary for today
  Future<Map<String, double>> getTodayNutritionSummary() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final todayMeals = await getTodayMeals();

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var meal in todayMeals) {
      totalCalories += meal.calories;
      totalProtein += meal.protein;
      totalCarbs += meal.carbs;
      totalFat += meal.fat;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  Future<double> getTodayWaterSummary() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final todayWater = await getTodayWaterIntakes();
    return todayWater.fold<double>(0.0, (sum, water) => sum + water.amount);
  }

  /// 🔹 Deletion
  Future<void> deleteMeal(String mealId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _meals.removeWhere((meal) => meal.id == mealId);
  }

  Future<void> deleteWaterIntake(String waterId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _waterIntakes.removeWhere((water) => water.id == waterId);
  }
}
