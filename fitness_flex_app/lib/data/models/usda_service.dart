import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

class USDAService {
  static const String apiKey = "Akb8A33VjAPLOBkB6qcaC4tzBBhStuHK7xum8jb8";
  static const String baseUrl = "https://api.nal.usda.gov/fdc/v1/foods/search";

  static Future<List<FoodItem>> searchFoods(String query) async {
    final response = await http.get(
      Uri.parse("$baseUrl?query=$query&pageSize=10&api_key=$apiKey"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final foods = data['foods'] as List? ?? [];
      return foods.map((f) => FoodItemUSDA.fromUSDAJson(f)).toList();
    } else {
      throw Exception("USDA API error: ${response.statusCode}");
    }
  }
}
