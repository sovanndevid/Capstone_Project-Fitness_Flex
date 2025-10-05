import 'package:cloud_firestore/cloud_firestore.dart';

class ExercisePlan {
  final String id;
  final String name;
  final String gifUrl;
  final String bodyPart;
  final String equipment;
  final String target;   // keep empty string if unknown
  final int sets;
  final int reps;
  final int restSec;

  const ExercisePlan({
    required this.id,
    required this.name,
    required this.gifUrl,
    required this.bodyPart,
    required this.equipment,
    this.target = '',
    this.sets = 3,
    this.reps = 12,
    this.restSec = 60,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'gifUrl': gifUrl,
        'bodyPart': bodyPart,
        'equipment': equipment,
        'target': target,
        'sets': sets,
        'reps': reps,
        'restSec': restSec,
      };

  factory ExercisePlan.fromMap(Map<String, dynamic> m) => ExercisePlan(
        id: (m['id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        gifUrl: (m['gifUrl'] ?? '') as String,
        bodyPart: (m['bodyPart'] ?? '') as String,
        equipment: (m['equipment'] ?? '') as String,
        target: (m['target'] ?? '') as String,
        sets: (m['sets'] ?? 3) as int,
        reps: (m['reps'] ?? 12) as int,
        restSec: (m['restSec'] ?? 60) as int,
      );
}

class WorkoutDoc {
  final String id; // Firestore document id
  final String name;
  final String category;     // 'strength' etc.
  final String difficulty;   // 'beginner' etc.
  final String source;       // 'preset' | 'search' | 'ai' | 'custom'
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int durationMin;
  final int caloriesBurned;
  final List<ExercisePlan> exercises;

  const WorkoutDoc({
    required this.id,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.source,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    this.durationMin = 0,
    this.caloriesBurned = 0,
    this.exercises = const [],
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'difficulty': difficulty,
        'source': source,
        'createdAt': Timestamp.fromDate(createdAt),
        if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt!),
        if (finishedAt != null) 'finishedAt': Timestamp.fromDate(finishedAt!),
        'durationMin': durationMin,
        'caloriesBurned': caloriesBurned,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };

  factory WorkoutDoc.fromSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final m = snap.data()!;
    List<ExercisePlan> plans = [];
    final raw = m['exercises'];
    if (raw is List) {
      plans = raw
          .whereType<Map<String, dynamic>>()
          .map(ExercisePlan.fromMap)
          .toList();
    }
    DateTime? _toDate(dynamic v) =>
        (v is Timestamp) ? v.toDate() : (v is DateTime ? v : null);

    return WorkoutDoc(
      id: snap.id,
      name: (m['name'] ?? '') as String,
      category: (m['category'] ?? '') as String,
      difficulty: (m['difficulty'] ?? '') as String,
      source: (m['source'] ?? 'custom') as String,
      createdAt: _toDate(m['createdAt']) ?? DateTime.now(),
      startedAt: _toDate(m['startedAt']),
      finishedAt: _toDate(m['finishedAt']),
      durationMin: (m['durationMin'] ?? 0) as int,
      caloriesBurned: (m['caloriesBurned'] ?? 0) as int,
      exercises: plans,
    );
  }
}

class SetLog {
  final String exerciseId;
  final String name;
  final int set;
  final int reps;
  final double weightKg;
  final int? restSec;
  final int? rpe;
  final DateTime ts;

  const SetLog({
    required this.exerciseId,
    required this.name,
    required this.set,
    required this.reps,
    required this.weightKg,
    this.restSec,
    this.rpe,
    required this.ts,
  });

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'name': name,
        'set': set,
        'reps': reps,
        'weightKg': weightKg,
        if (restSec != null) 'restSec': restSec,
        if (rpe != null) 'rpe': rpe,
        'ts': Timestamp.fromDate(ts),
      };

  factory SetLog.fromSnap(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    final ts = (m['ts'] as Timestamp?)?.toDate() ?? DateTime.now();
    return SetLog(
      exerciseId: (m['exerciseId'] ?? '') as String,
      name: (m['name'] ?? '') as String,
      set: (m['set'] ?? 1) as int,
      reps: (m['reps'] ?? 0) as int,
      weightKg: (m['weightKg'] ?? 0.0).toDouble(),
      restSec: (m['restSec'] as num?)?.toInt(),
      rpe: (m['rpe'] as num?)?.toInt(),
      ts: ts,
    );
  }
}
