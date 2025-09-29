// lib/data/repositories/workout_repository.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fitness_flex_app/data/models/workout_model.dart';
import 'package:fitness_flex_app/data/models/workout_builder.dart';
import 'package:fitness_flex_app/data/models/exercise.dart';
import 'package:fitness_flex_app/data/models/exercise_api.dart';

/// Helpers to convert between enum and wire/string values.
extension WorkoutCategoryWire on WorkoutCategory {
  /// lowercase token we use in requests / routing
  String get wire => name.toLowerCase(); // e.g. "Strength Training" -> "strength"
  static WorkoutCategory fromWire(String wire) {
    switch (wire.toLowerCase()) {
      case 'strength':
      case 'strength training':
        return WorkoutCategory.strength;
      case 'cardio':
        return WorkoutCategory.cardio;
      case 'yoga':
      case 'yoga & flexibility':
        return WorkoutCategory.yoga;
      case 'hiit':
        return WorkoutCategory.hiit;
      case 'custom':
      default:
        return WorkoutCategory.custom;
    }
  }
}

/// Single dynamic repo (ExerciseDB + optional Firestore favorites).
class WorkoutRepository {
  WorkoutRepository({
    FirebaseFirestore? firestore,
    this.userId,
  }) : _db = firestore;

  final FirebaseFirestore? _db; // pass Firestore to enable favorites
  final String? userId;

  // caches
  List<Workout>? _cacheAll;
  final Map<String, List<Workout>> _cacheByCategory = {};
  Set<String> _favoriteIds = {};

  /* ----------------------- Favorites ----------------------- */

  Future<void> _loadFavorites() async {
    if (_db == null || userId == null) return;
    final qs = await _db!
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();
    _favoriteIds = qs.docs.map((d) => d.id).toSet();
  }

  bool _fav(String id) => _favoriteIds.contains(id);

  /* ----------------------- Builders ------------------------ */

  Workout _buildWorkout({
    required String title,
    required List<Exercise> items,
    required WorkoutCategory category,
    required WorkoutDifficulty difficulty,
    String description = '',
  }) {
    final id =
        '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    final image = items.isNotEmpty ? items.first.gifUrl : '';

    final w = WorkoutBuilder.fromExercises(
      id: id,
      title: title,
      description: description.isNotEmpty
          ? description
          : '${category.name} session (${difficulty.name})',
      imageUrl: image,
      items: items.take(6).toList(), // keep ~6 items for UX
      category: category,
      difficulty: difficulty,
    );

    return w.copyWith(isFavorite: _fav(w.id));
  }

  Future<List<Workout>> _bootstrapCurated() async {
    // pull several lists in parallel to keep it snappy
    final results = await Future.wait<List<Exercise>>([
      ExerciseApi.filter(bodyPart: 'chest', equipment: 'barbell'), // push
      ExerciseApi.filter(bodyPart: 'back', equipment: 'barbell'), // pull
      ExerciseApi.filter(
          bodyPart: 'quadriceps', equipment: 'barbell'), // legs (dataset-dependent)
      ExerciseApi.byEquipment('dumbbell'), // full body dumbbells
    ]);

    final push = _buildWorkout(
      title: 'Push Day – Chest Focus',
      items: results[0],
      category: WorkoutCategory.strength,
      difficulty: WorkoutDifficulty.intermediate,
      description: 'Compound chest/shoulder/triceps session.',
    );

    final pull = _buildWorkout(
      title: 'Pull Day – Back Focus',
      items: results[1],
      category: WorkoutCategory.strength,
      difficulty: WorkoutDifficulty.intermediate,
      description: 'Rows, pulls, and posterior chain.',
    );

    final legs = _buildWorkout(
      title: 'Leg Day – Barbell',
      items: results[2],
      category: WorkoutCategory.strength,
      difficulty: WorkoutDifficulty.intermediate,
      description: 'Squat patterns and hinge variations.',
    );

    final dbFullBody = _buildWorkout(
      title: 'Full Body – Dumbbells',
      items: results[3],
      category: WorkoutCategory.strength,
      difficulty: WorkoutDifficulty.beginner,
      description: 'Accessible total-body session.',
    );

    return [push, pull, legs, dbFullBody];
  }

  /* ----------------------- Public API ---------------------- */

  Future<List<WorkoutCategory>> getCategories() async => const [
        WorkoutCategory.strength,
        WorkoutCategory.cardio,
        WorkoutCategory.yoga,
        WorkoutCategory.hiit,
        WorkoutCategory.custom,
      ];

  /// Main feed: curated + (optional) search add-on, favorites respected.
  Future<List<Workout>> getWorkouts() async {
    if (_cacheAll != null) return _cacheAll!;
    await _loadFavorites();

    // curated (reliable)
    final curated = await _bootstrapCurated();

    // optional: search add-on; never let a search failure break the feed
    try {
      // IMPORTANT: search must send `q`, not `query`
      final searchAdds = await ExerciseApi.search('press');
      if (searchAdds.isNotEmpty) {
        final add = _buildWorkout(
          title: 'Upper Body – Pressing',
          items: searchAdds.take(6).toList(),
          category: WorkoutCategory.strength,
          difficulty: WorkoutDifficulty.intermediate,
          description: 'Bench/overhead press emphasis.',
        );
        curated.add(add);
      }
    } catch (_) {
      // swallow; curated still shows
    }

    _cacheAll = curated.map((w) => w.copyWith(isFavorite: _fav(w.id))).toList();
    return _cacheAll!;
  }

  /// Category feed built from ExerciseDB filters.
  Future<List<Workout>> getWorkoutsByCategory(String categoryWire) async {
    if (_cacheByCategory.containsKey(categoryWire)) {
      return _cacheByCategory[categoryWire]!;
    }
    await _loadFavorites();

    final cat = WorkoutCategoryWire.fromWire(categoryWire);
    List<Exercise> items;

    switch (cat) {
      case WorkoutCategory.strength:
        items = await ExerciseApi.byEquipment('barbell');
        break;
      case WorkoutCategory.cardio:
        // dataset is strength-biased; approximate cardio with dynamic bodyweight
        items = await ExerciseApi.byEquipment('body weight');
        break;
      case WorkoutCategory.yoga:
        // no pure yoga; use mobility + bodyweight
        items = await ExerciseApi.filter(equipment: 'body weight');
        break;
      case WorkoutCategory.hiit:
        items = await ExerciseApi.filter(equipment: 'body weight');
        break;
      case WorkoutCategory.custom:
        // list() returns a tuple; take the first element (list)
        final tuple = await ExerciseApi.list(limit: 20, offset: 0);
        items = tuple.$1;
        break;
    }

    final built = _buildWorkout(
      title: '${cat.name} Session',
      items: items.take(8).toList(),
      category: cat,
      difficulty: (cat == WorkoutCategory.hiit)
          ? WorkoutDifficulty.advanced
          : WorkoutDifficulty.beginner,
      description: 'Auto-generated by filters.',
    );

    _cacheByCategory[categoryWire] = [
      built.copyWith(isFavorite: _fav(built.id))
    ];
    return _cacheByCategory[categoryWire]!;
  }

  Future<List<Workout>> getFavoriteWorkouts() async {
    if (_db == null || userId == null) return [];
    await _loadFavorites();
    final all = await getWorkouts();
    return all.where((w) => _favoriteIds.contains(w.id)).toList();
  }

  /// Toggle favorite in Firestore: users/{uid}/favorites/{workoutId}
  Future<void> toggleFavorite(String workoutId) async {
    if (_db == null || userId == null) return;
    final ref = _db!
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(workoutId);

    if (_favoriteIds.contains(workoutId)) {
      await ref.delete();
      _favoriteIds.remove(workoutId);
    } else {
      await ref.set({'ts': DateTime.now().toIso8601String()});
      _favoriteIds.add(workoutId);
    }

    // bust caches so isFavorite recalculates
    _cacheAll = null;
    _cacheByCategory.clear();
  }

  Future<List<Workout>> getPopularWorkouts() async {
    final all = await getWorkouts();
    return all.take(3).toList();
  }

  /* ---------------- Search & Instant Workouts --------------- */

  /// Raw exercise search
  Future<List<Exercise>> searchExercises(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    return ExerciseApi.search(q);
  }

  /// Filtered exercise search (chips)
  Future<List<Exercise>> filterExercises({
    String? bodyPart,
    String? equipment,
    String? muscle,
  }) async {
    return ExerciseApi.filter(
      bodyPart: bodyPart,
      equipment: equipment,
      muscle: muscle,
    );
  }

  /// Create a one-off workout from exercises
  Workout buildInstantWorkout({
    required String title,
    required List<Exercise> items,
    WorkoutCategory category = WorkoutCategory.strength,
    WorkoutDifficulty difficulty = WorkoutDifficulty.beginner,
    String description = '',
  }) {
    return _buildWorkout(
      title: title,
      items: items,
      category: category,
      difficulty: difficulty,
      description: description.isEmpty ? 'Results for "$title"' : description,
    );
  }

  /// Quick helper: query -> workout (top 8 results)
  Future<Workout?> searchToWorkout(String q) async {
    final hits = await searchExercises(q);
    if (hits.isEmpty) return null;
    return buildInstantWorkout(
      title: q,
      items: hits.take(8).toList(),
    );
  }
}
