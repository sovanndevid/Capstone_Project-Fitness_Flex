import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutLog {
  final String id;
  final String workoutId;
  final String title;
  final int duration; // minutes if known, else 0
  final int calories; // if known, else 0
  final DateTime completedAt;

  WorkoutLog({
    required this.id,
    required this.workoutId,
    required this.title,
    required this.duration,
    required this.calories,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() => {
        'workoutId': workoutId,
        'title': title,
        'duration': duration,
        'calories': calories,
        'completedAt': Timestamp.fromDate(completedAt),
      };

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      final m = RegExp(r'\d+').firstMatch(v);
      return m != null ? int.tryParse(m.group(0)!) ?? 0 : 0;
    }
    return 0;
  }

  static WorkoutLog fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return WorkoutLog(
      id: doc.id,
      workoutId: (d['workoutId'] as String?) ?? '',
      title: (d['title'] as String?) ?? '',
      duration: _toInt(d['duration']),
      calories: _toInt(d['calories']),
      completedAt: (d['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}