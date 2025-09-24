import 'package:cloud_firestore/cloud_firestore.dart';

class Meal {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime date;       // stored as Firestore Timestamp
  final String mealType;     // breakfast, lunch, dinner, snack
  final int servingSize;

  Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.date,
    required this.mealType,
    required this.servingSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      // Save as Firestore Timestamp for reliable range queries
      'timestamp': Timestamp.fromDate(date),
      'mealType': mealType,
      'servingSize': servingSize,
    };
  }

  /// Backward-compatible: accepts either Timestamp (`timestamp`) or ISO string (`date`)
  factory Meal.fromMap(Map<String, dynamic> map, {String? docId}) {
    final Object? ts = map['timestamp'] ?? map['date'];
    DateTime when;

    if (ts is Timestamp) {
      when = ts.toDate();
    } else if (ts is String) {
      // legacy ISO string
      when = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      when = DateTime.now();
    }

    return Meal(
      id: (docId ?? map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      calories: (map['calories'] as num? ?? 0).toDouble(),
      protein: (map['protein'] as num? ?? 0).toDouble(),
      carbs: (map['carbs'] as num? ?? 0).toDouble(),
      fat: (map['fat'] as num? ?? 0).toDouble(),
      date: when,
      mealType: (map['mealType'] ?? 'breakfast').toString(),
      servingSize: (map['servingSize'] as num? ?? 1).toInt(),
    );
  }

  /// Convenience for Firestore docs
  factory Meal.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Meal.fromMap(data, docId: doc.id);
  }
}
