import 'package:fitness_flex_app/data/models/meal.dart';
import 'package:fitness_flex_app/data/models/water_intake.dart';
import 'package:fitness_flex_app/data/models/nutrition_goal.dart';
import 'package:fitness_flex_app/data/models/food_item.dart';

class NutritionRepository {
  // Updated food database
  final List<FoodItem> foodDatabase = [
    // Protein Sources
    FoodItem(
      id: '1',
      name: 'Chicken Breast',
      brand: 'Generic',
      calories: 165,
      protein: 31,
      carbs: 0,
      fat: 3.6,
      servingSize: 100,
      servingUnit: 'g',
    ),
    FoodItem(
      id: '2',
      name: 'Salmon',
      brand: 'Generic',
      calories: 208,
      protein: 20,
      carbs: 0,
      fat: 13,
      servingSize: 100,
      servingUnit: 'g',
    ),
    FoodItem(
      id: '3',
      name: 'Eggs',
      brand: 'Generic',
      calories: 155,
      protein: 13,
      carbs: 1.1,
      fat: 11,
      servingSize: 100,
      servingUnit: 'g',
    ),
    FoodItem(
      id: '4',
      name: 'Greek Yogurt',
      brand: 'Generic',
      calories: 59,
      protein: 10,
      carbs: 3.6,
      fat: 0.4,
      servingSize: 100,
      servingUnit: 'g',
    ),
    FoodItem(
      id: '5',
      name: 'Tofu',
      brand: 'Generic',
      calories: 76,
      protein: 8,
      carbs: 1.9,
      fat: 4.8,
      servingSize: 100,
      servingUnit: 'g',
    ),

    // Carbs Sources
    FoodItem(
      id: '6',
      name: 'Brown Rice',
      brand: 'Generic',
      calories: 111,
      protein: 2.6,
      carbs: 23,
      fat: 0.9,
      servingSize: 100,
      servingUnit: 'g',
    ),
    FoodItem(
      id: '7',
      name: 'Oats',
      brand: 'Generic',
      calories: 389,
      protein: 17,
      carbs: 66,
      fat: 7,
      servingSize: 100,
      servingUnit: 'g',
    ),
    FoodItem(
      id: '8',
      name: 'Sweet Potato',
      brand: 'Generic',
      calories: 86,
      protein: 1.6,
      carbs: 20,
      fat: 0.1,
      servingSize: 100,
      servingUnit: 'g',
    ),
    FoodItem(
      id: '9',
      name: 'Whole Wheat Bread',
      brand: 'Generic',
      calories: 247,
      protein: 13,
      carbs: 41,
      fat: 3.4,
      servingSize: 100,
      servingUnit: 'g',
    ),
    FoodItem(
      id: '10',
      name: 'Quinoa',
      brand: 'Generic',
      calories: 120,
      protein: 4.4,
      carbs: 21,
      fat: 1.9,
      servingSize: 100,
      servingUnit: 'g',
    ),

    // Vegetables
    FoodItem(
      id: '11',
      name: 'Broccoli',
      brand: 'Generic',
      calories: 34,
      protein: 2.8,
      carbs: 7,
      fat: 0.4,
      servingSize: 100,
      servingUnit: 'g',
    ),
    FoodItem(
      id: '12',
      name: 'Spinach',
      brand: 'Generic',
      calories: 23,
      protein: 2.9,
      carbs: 3.6,
      fat: 0.4,
      servingSize: 100,
      servingUnit: 'g',
    ),
    FoodItem(
      id: '13',
      name: 'Carrots',
      brand: 'Generic',
      calories: 41,
      protein: 0.9,
      carbs: 10,
      fat: 0.2,
      servingSize: 100,
      servingUnit: 'g',
    ),

    // Fruits
    FoodItem(
      id: '14',
      name: 'Banana',
      brand: 'Generic',
      calories: 89,
      protein: 1.1,
      carbs: 23,
      fat: 0.3,
      servingSize: 100,
      servingUnit: 'g',
    ),
    FoodItem(
      id: '15',
      name: 'Apple',
      brand: 'Generic',
      calories: 52,
      protein: 0.3,
      carbs: 14,
      fat: 0.2,
      servingSize: 100,
      servingUnit: 'g',
    ),
    FoodItem(
      id: '16',
      name: 'Orange',
      brand: 'Generic',
      calories: 47,
      protein: 0.9,
      carbs: 12,
      fat: 0.1,
      servingSize: 100,
      servingUnit: 'g',
    ),

    // Snacks
    FoodItem(
      id: '17',
      name: 'Almonds',
      brand: 'Generic',
      calories: 579,
      protein: 21,
      carbs: 22,
      fat: 50,
      servingSize: 100,
      servingUnit: 'g',
    ),
    FoodItem(
      id: '18',
      name: 'Protein Bar',
      brand: 'Generic',
      calories: 200,
      protein: 20,
      carbs: 15,
      fat: 8,
      servingSize: 1,
      servingUnit: 'bar',
    ),
  ];

  final List<Meal> _meals = [];
  final List<WaterIntake> _waterIntakes = [];
  NutritionGoal _nutritionGoal = NutritionGoal(
    dailyCalories: 2000,
    dailyProtein: 150,
    dailyCarbs: 250,
    dailyFat: 70,
    dailyWater: 2.5,
  );

  Future<List<FoodItem>> searchFood(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (query.isEmpty) return [];
    return foodDatabase
        .where((food) => food.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

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

  Future<void> addMeal(Meal meal) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _meals.add(meal);
  }

  Future<void> addWaterIntake(WaterIntake waterIntake) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _waterIntakes.add(waterIntake);
  }

  Future<NutritionGoal> getNutritionGoal() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _nutritionGoal;
  }

  Future<void> updateNutritionGoal(NutritionGoal goal) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _nutritionGoal = goal;
  }

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

  Future<void> deleteMeal(String mealId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _meals.removeWhere((meal) => meal.id == mealId);
  }

  Future<void> deleteWaterIntake(String waterId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _waterIntakes.removeWhere((water) => water.id == waterId);
  }
}
