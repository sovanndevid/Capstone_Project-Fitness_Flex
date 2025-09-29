// lib/data/services/exercise_api.dart (or your actual path)
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/exercise.dart';

class ExerciseApi {
  static const _base = 'https://exercise-backend-alpha.vercel.app/api/v1';

  static Future<Map<String, dynamic>> _get(String path, [Map<String, String>? qp]) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: qp);
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<Exercise>> list({int limit = 20, int offset = 0}) async {
    final body = await _get('/exercises', {'limit': '$limit', 'offset': '$offset'});
    return (body['data'] as List).map((e) => Exercise.fromExDb(e)).toList();
  }


  static Future<List<Exercise>> search(String q) async {

    final body = await _get('/exercises/search', {'q': q});
    return (body['data'] as List).map((e) => Exercise.fromExDb(e)).toList();
  }


  static Future<List<Exercise>> filter({String? bodyPart, String? equipment, String? muscle}) async {
    final qp = <String, String>{};
    if (bodyPart != null) qp['bodyPart'] = bodyPart;
    if (equipment != null) qp['equipment'] = equipment;
    if (muscle != null) qp['muscle'] = muscle;
    final body = await _get('/exercises/filter', qp);
    return (body['data'] as List).map((e) => Exercise.fromExDb(e)).toList();
  }

  static Future<List<Exercise>> byEquipment(String name) async {
    final body = await _get('/equipments/${Uri.encodeComponent(name)}/exercises');
    return (body['data'] as List).map((e) => Exercise.fromExDb(e)).toList();
  }
}
