import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fitness_flex_app/data/models/meal.dart';
import 'package:fitness_flex_app/data/models/water_intake.dart';
import 'package:fitness_flex_app/data/models/nutrition_goal.dart';
import 'package:fitness_flex_app/data/models/food_item.dart';
import 'package:fitness_flex_app/data/models/ausnut_service.dart';

/// --- Main Repository ---
class NutritionRepository {
  // ---------- External food sources ----------
  static const String _usdaApiKey = "Akb8A33VjAPLOBkB6qcaC4tzBBhStuHK7xum8jb8";
  static const String _usdaBaseUrl =
      "https://api.nal.usda.gov/fdc/v1/foods/search";

  // ---------- Firebase (for meals + goals only) ----------
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw StateError('User is not logged in.');
    return u.uid;
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ---------- In-memory (leave WaterTracker as-is) ----------
  final List<WaterIntake> _waterIntakes =
      []; // legacy (no longer primary storage)

  // ---------- Default goal fallback (shown if Firestore has no macros) ----------
  NutritionGoal _fallbackGoal = NutritionGoal(
    dailyCalories: 2000,
    dailyProtein: 150,
    dailyCarbs: 250,
    dailyFat: 70,
    dailyWater: 2.5,
  );

  // ======================================================
  //                  FOOD SEARCH (unchanged)
  // ======================================================
  Future<List<FoodItem>> searchFood(String query) async {
    if (query.trim().isEmpty) return [];

    final List<FoodItem> results = [];

    // USDA
    try {
      final r = await http.get(
        Uri.parse(
          "$_usdaBaseUrl?query=$query&pageSize=10&api_key=$_usdaApiKey",
        ),
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final foods = (data['foods'] as List?) ?? [];
        results.addAll(foods.map((f) => FoodItemUSDA.fromUSDAJson(f)).toList());
      }
    } catch (_) {}

    // AUSNUT
    try {
      final ausnutFoods = await AUSNUTService.searchFoods(query);
      results.addAll(ausnutFoods);
    } catch (_) {}

    return results;
  }

  // ======================================================
  //                        MEALS (Firestore)
  // ======================================================
  Future<void> addMeal(Meal meal) async {
    await _users
        .doc(_uid)
        .collection('meals')
        .doc(meal.id)
        .set(meal.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteMeal(String mealId) async {
    await _users.doc(_uid).collection('meals').doc(mealId).delete();
  }

  /// Meals logged today (00:00–24:00) using Firestore Timestamp
  Future<List<Meal>> getTodayMeals() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final snap = await _users
        .doc(_uid)
        .collection('meals')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .get();

    return snap.docs.map((d) => Meal.fromDoc(d)).toList();
  }

  /// Aggregate macros from today's meals
  Future<Map<String, double>> getTodayNutritionSummary() async {
    final meals = await getTodayMeals();
    double totalCalories = 0, totalProtein = 0, totalCarbs = 0, totalFat = 0;

    for (final m in meals) {
      totalCalories += m.calories;
      totalProtein += m.protein;
      totalCarbs += m.carbs;
      totalFat += m.fat;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  // ======================================================
  //                        GOALS (Firestore)
  // ======================================================
  Future<NutritionGoal> getNutritionGoal() async {
    final userDoc = await _users.doc(_uid).get();
    final data = userDoc.data() ?? {};
    final macros = (data['macros'] as Map<String, dynamic>?);

    if (macros == null) return _fallbackGoal;

    return NutritionGoal(
      dailyCalories: (macros['calories'] as num? ?? _fallbackGoal.dailyCalories)
          .toDouble(),
      dailyProtein: (macros['protein'] as num? ?? _fallbackGoal.dailyProtein)
          .toDouble(),
      dailyCarbs: (macros['carbs'] as num? ?? _fallbackGoal.dailyCarbs)
          .toDouble(),
      dailyFat: (macros['fat'] as num? ?? _fallbackGoal.dailyFat).toDouble(),
      dailyWater: _fallbackGoal
          .dailyWater, // keep default unless you add it in Firestore
    );
  }

  Future<void> updateNutritionGoal(NutritionGoal goal) async {
    _fallbackGoal = goal; // also update local fallback
    await _users.doc(_uid).set({
      'macros': {
        'calories': goal.dailyCalories,
        'protein': goal.dailyProtein,
        'carbs': goal.dailyCarbs,
        'fat': goal.dailyFat,
      },
    }, SetOptions(merge: true));
  }

  // ======================================================
  //                      WATER (IN-MEMORY)
  // ======================================================
  // ---------- WATER (Firestore persistence) ----------
  CollectionReference<Map<String, dynamic>> get _hydrationCol =>
      _users.doc(_uid).collection('hydration_logs');

  Future<void> addWaterIntake(WaterIntake waterIntake) async {
    // Store both liters and milliliters for flexibility
    await _hydrationCol.doc(waterIntake.id).set({
      'id': waterIntake.id,
      'date': Timestamp.fromDate(waterIntake.date),
      'amountL': waterIntake.amount,
      'ml': (waterIntake.amount * 1000).round(),
      'time': waterIntake.time,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<WaterIntake>> getTodayWaterIntakes() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final snap = await _hydrationCol
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return snap.docs.map((d) {
      final data = d.data();
      final ts = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
      final amountL =
          (data['amountL'] as num?)?.toDouble() ??
          ((data['ml'] as num?)?.toDouble() ?? 0) / 1000.0;
      return WaterIntake(
        id: (data['id'] as String?) ?? d.id,
        date: ts,
        amount: amountL,
        time: (data['time'] as String?) ?? fmt(ts),
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<double> getTodayWaterSummary() async {
    final intakes = await getTodayWaterIntakes();
    return intakes.fold<double>(0.0, (s, w) => s + w.amount);
  }

  Future<void> deleteWaterIntake(String waterId) async {
    await _hydrationCol.doc(waterId).delete();
  }
}
