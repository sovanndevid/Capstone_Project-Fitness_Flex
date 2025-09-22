import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

class AUSNUTService {
  static const String baseUrl =
      "https://studybuddy-backend-git-main-sovanndevidnong-admins-projects.vercel.app/api/ausnut";

  /// 🔹 Search foods (uses lightweight parser)
  static Future<List<FoodItem>> searchFoods(String query) async {
    final response = await http.get(Uri.parse("$baseUrl/search?q=$query"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final foods = data['foods'] as List? ?? [];
      return foods.map((f) => FoodItemAUSNUT.fromAUSNUTSearchJson(f)).toList();
    } else {
      throw Exception("AUSNUT API error: ${response.statusCode}");
    }
  }

  /// 🔹 Get food details (uses nutrient parser)
  static Future<FoodItem> getFoodDetails(String id) async {
    final response = await http.get(Uri.parse("$baseUrl/food?id=$id"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return FoodItemAUSNUT.fromAUSNUTDetailJson(data);
    } else {
      throw Exception("AUSNUT API error: ${response.statusCode}");
    }
  }
}
