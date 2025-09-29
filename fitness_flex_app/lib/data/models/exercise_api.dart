import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fitness_flex_app/data/models/exercise.dart';

class ExerciseApi {
  static const String _baseUrl = 'https://exercise-backend-alpha.vercel.app/api/v1';

  static Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: q);

  static Future<Map<String, dynamic>> _getJson(Uri url) async {
    final res = await http.get(url, headers: {'Accept': 'application/json'});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body;
  }

  /* ---------- Endpoints ---------- */

  /// Search exercises by text. API requires `q`, not `query`.
  static Future<List<Exercise>> search(String q) async {
    final json = await _getJson(_u('/exercises/search', {'q': q}));
    final data = (json['data'] as List?) ?? const [];
    return data.map((e) => Exercise.fromExDb(e)).toList();
  }

  /// Paged list
  static Future<(List<Exercise>, int)> list({int limit = 20, int offset = 0}) async {
    final json = await _getJson(_u('/exercises', {
      'limit': '$limit',
      'offset': '$offset',
    }));
    final data = (json['data'] as List?) ?? const [];
    final total = (json['total'] as num?)?.toInt() ?? data.length;
    return (data.map((e) => Exercise.fromExDb(e)).toList(), total);
  }

  /// Filter by any combo
  static Future<List<Exercise>> filter({
    String? bodyPart,
    String? equipment,
    String? muscle,
  }) async {
    final qp = <String, String>{};
    if (bodyPart != null && bodyPart.isNotEmpty) qp['bodyPart'] = bodyPart;
    if (equipment != null && equipment.isNotEmpty) qp['equipment'] = equipment;
    if (muscle != null && muscle.isNotEmpty) qp['muscle'] = muscle;
    final json = await _getJson(_u('/exercises/filter', qp));
    final data = (json['data'] as List?) ?? const [];
    return data.map((e) => Exercise.fromExDb(e)).toList();
  }

  static Future<List<Exercise>> byBodyPart(String bodyPart) async {
    final json = await _getJson(_u('/bodyparts/$bodyPart/exercises'));
    final data = (json['data'] as List?) ?? const [];
    return data.map((e) => Exercise.fromExDb(e)).toList();
  }

  static Future<List<Exercise>> byEquipment(String equipment) async {
    final json = await _getJson(_u('/equipments/$equipment/exercises'));
    final data = (json['data'] as List?) ?? const [];
    return data.map((e) => Exercise.fromExDb(e)).toList();
  }

  static Future<List<Exercise>> byMuscle(String muscle) async {
    final json = await _getJson(_u('/muscles/$muscle/exercises'));
    final data = (json['data'] as List?) ?? const [];
    return data.map((e) => Exercise.fromExDb(e)).toList();
  }
}
