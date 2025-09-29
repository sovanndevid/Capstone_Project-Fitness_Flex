import 'exercise.dart';
import '../models/workout_model.dart';

class Defaults {
  static ({int sets, int reps, String rest}) perDifficulty(WorkoutDifficulty d) {
    switch (d) {
      case WorkoutDifficulty.beginner: return (sets: 3, reps: 12, rest: '60s');
      case WorkoutDifficulty.intermediate: return (sets: 4, reps: 10, rest: '90s');
      case WorkoutDifficulty.advanced: return (sets: 5, reps: 8, rest: '120s');
    }
  }
}

WorkoutExercise toWorkoutExercise(
  Exercise ex, {
  WorkoutDifficulty difficulty = WorkoutDifficulty.beginner,
  String perExerciseDuration = '',
}) {
  final d = Defaults.perDifficulty(difficulty);
  return WorkoutExercise(
    id: ex.id,
    name: ex.name,
    description: ex.instructions.join('\n'),
    imageUrl: ex.gifUrl,
    videoUrl: '',
    duration: perExerciseDuration,
    sets: d.sets,
    reps: d.reps,
    restTime: d.rest,
  );
}

class WorkoutBuilder {
  static String estimateDuration(List<WorkoutExercise> xs) {
    int totalSec = 0;
    for (final e in xs) {
      final rest = _parseRest(e.restTime);
      totalSec += e.sets * (40 + rest); // ~40s effort + rest
    }
    final m = (totalSec / 60).round().clamp(10, 120);
    return '${m}m';
  }

  static int estimateCalories(WorkoutDifficulty d, int minutes) {
    final met = switch (d) {
      WorkoutDifficulty.beginner => 4.5,
      WorkoutDifficulty.intermediate => 6.0,
      WorkoutDifficulty.advanced => 7.5,
    };
    return (met * 1.25 * minutes).round(); // ~75kg
  }

  static int _parseRest(String rest) {
    final s = rest.trim().toLowerCase();
    if (s.endsWith('s')) return int.tryParse(s.replaceAll('s', '')) ?? 60;
    if (s.contains(':')) {
      final parts = s.split(':');
      if (parts.length == 2) {
        final mm = int.tryParse(parts[0]) ?? 0;
        final ss = int.tryParse(parts[1]) ?? 0;
        return mm * 60 + ss;
      }
    }
    return int.tryParse(s) ?? 60;
  }

  static Workout fromExercises({
    required String id,
    required String title,
    required String description,
    required String imageUrl,
    required List<Exercise> items,
    WorkoutCategory category = WorkoutCategory.strength,
    WorkoutDifficulty difficulty = WorkoutDifficulty.beginner,
    String equipment = '',
    String focusArea = '',
  }) {
    final exercises = items.map((e) => toWorkoutExercise(e, difficulty: difficulty)).toList();

    final durStr = estimateDuration(exercises);
    final minutes = int.tryParse(durStr.replaceAll('m', '')) ?? 45;
    final kcal = estimateCalories(difficulty, minutes);

    String majority(Iterable<String> vals) {
      final m = <String, int>{};
      for (final v in vals) {
        if (v.isEmpty) continue;
        m[v] = (m[v] ?? 0) + 1;
      }
      if (m.isEmpty) return '';
      return m.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    return Workout(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl,
      duration: durStr,
      calories: kcal,
      difficulty: difficulty.wire, // store strings (back-compat)
      exercises: exercises,
      category: category.wire,     // store strings (back-compat)
      equipment: equipment.isNotEmpty ? equipment : majority(items.map((e) => e.equipment)),
      focusArea: focusArea.isNotEmpty ? focusArea : majority(items.map((e) => e.bodyPart)),
      isFavorite: false,
    );
  }
}
