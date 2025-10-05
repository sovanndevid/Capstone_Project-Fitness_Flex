// lib/data/repositories/workout_repository.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fitness_flex_app/data/models/workout_model.dart';
import 'package:fitness_flex_app/data/models/workout_builder.dart';
import 'package:fitness_flex_app/data/models/exercise.dart';
import 'package:fitness_flex_app/data/models/exercise_api.dart';

/// Helpers to convert between enum and wire/string values.
extension WorkoutCategoryWire on WorkoutCategory {
  String get wire => name.toLowerCase();
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

/// Unified repository for workouts from ExerciseDB + Firestore favorites.
class WorkoutRepository {
  WorkoutRepository({FirebaseFirestore? firestore, this.userId}) : _db = firestore;

  final FirebaseFirestore? _db;
  final String? userId;

  List<Workout>? _cacheAll;
  final Map<String, List<Workout>> _cacheByCategory = {};
  Set<String> _favoriteIds = {};

  /* ---------------- FAVORITES ---------------- */

  Future<void> _loadFavorites() async {
    if (_db == null || userId == null) return;
    final qs = await _db!.collection('users').doc(userId).collection('favorites').get();
    _favoriteIds = qs.docs.map((d) => d.id).toSet();
  }

  bool _fav(String id) => _favoriteIds.contains(id);

  /* ---------------- BUILDERS ---------------- */

  Workout _buildWorkout({
    required String title,
    required List<Exercise> items,
    required WorkoutCategory category,
    required WorkoutDifficulty difficulty,
    String description = '',
  }) {
    final id = '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    final image = items.isNotEmpty ? items.first.gifUrl : '';

    final w = WorkoutBuilder.fromExercises(
      id: id,
      title: title,
      description: description.isNotEmpty
          ? description
          : '${category.name} session (${difficulty.name})',
      imageUrl: image,
      items: items.take(6).toList(),
      category: category,
      difficulty: difficulty,
    );

    return w.copyWith(isFavorite: _fav(w.id));
  }

  /* ---------------- UTILITIES ---------------- */

  /// Deduplicate by exercise id (ExerciseDB sometimes repeats).
  List<Exercise> _dedup(List<Exercise> xs) {
    final seen = <String>{};
    final out = <Exercise>[];
    for (final e in xs) {
      if (e.id.isEmpty) continue;
      if (seen.add(e.id)) out.add(e);
    }
    return out;
  }

  /// Strict include/exclude filtering on name/bodyPart/equipment.
  List<Exercise> _filterRelevant(
    List<Exercise> items,
    List<String> include, {
    List<String> exclude = const [],
  }) {
    final inc = include.map((e) => e.toLowerCase()).toList();
    final exc = exclude.map((e) => e.toLowerCase()).toList();

    return _dedup(items).where((e) {
      final name = e.name.toLowerCase();
      final body = e.bodyPart.toLowerCase();
      final equip = e.equipment.toLowerCase();

      final matchesInclude = inc.any((k) => name.contains(k) || body.contains(k) || equip.contains(k));
      final matchesExclude = exc.any((k) => name.contains(k) || body.contains(k) || equip.contains(k));

      return matchesInclude && !matchesExclude;
    }).toList();
  }

  /// Ensure we have at least [min] items by pulling extras and re-filtering.
  Future<List<Exercise>> _ensureAtLeast(
    List<Exercise> base,
    List<String> include, {
    List<String> exclude = const [],
    int min = 6,
    List<Future<List<Exercise>>> extras = const [],
  }) async {
    var out = _dedup(base);
    if (out.length >= min) return out;

    for (final fut in extras) {
      final more = await fut;
      final cleaned = _filterRelevant(more, include, exclude: exclude);
      out = _dedup([...out, ...cleaned]);
      if (out.length >= min) break;
    }
    return out;
  }

  /* ---------------- PUBLIC API ---------------- */

  Future<List<WorkoutCategory>> getCategories() async => const [
        WorkoutCategory.strength,
        WorkoutCategory.cardio,
        WorkoutCategory.yoga,
        WorkoutCategory.hiit,
        WorkoutCategory.custom,
      ];

  /* ------------ MAIN FEED (All Workouts) ------------ */
  Future<List<Workout>> getWorkouts() async {
    if (_cacheAll != null) return _cacheAll!;
    await _loadFavorites();

    // Merge curated slices from major categories for stability.
    final curated = <Workout>[];
    for (final cat in ['strength', 'cardio', 'yoga']) {
      curated.addAll(await getWorkoutsByCategory(cat));
    }

    // Add one general functional workout for variety.
    final tuple = await ExerciseApi.list(limit: 20, offset: 0);
    curated.add(_buildWorkout(
      title: 'Functional Full Body',
      items: _dedup(tuple.$1).take(8).toList(),
      category: WorkoutCategory.custom,
      difficulty: WorkoutDifficulty.intermediate,
      description: 'Balanced full-body circuit (mixed patterns).',
    ));

    _cacheAll = curated.map((w) => w.copyWith(isFavorite: _fav(w.id))).toList();
    return _cacheAll!;
  }

  /* ------------ CATEGORY FEEDS (strict + guaranteed min items) ------------ */
  Future<List<Workout>> getWorkoutsByCategory(String categoryWire) async {
    if (_cacheByCategory.containsKey(categoryWire)) {
      return _cacheByCategory[categoryWire]!;
    }
    await _loadFavorites();

    final cat = WorkoutCategoryWire.fromWire(categoryWire);
    final List<Workout> workouts = [];

    switch (cat) {
      /* ---------- STRENGTH ---------- */
      case WorkoutCategory.strength: {
        // Seed queries (focused)
        final chestSeed = await ExerciseApi.search('bench press');
        final backSeed  = await ExerciseApi.search('barbell row');
        final legsSeed  = await ExerciseApi.search('squat');

        // Initial strict cleanups
        var chestClean = _filterRelevant(
          chestSeed,
          ['bench', 'press', 'push', 'chest', 'overhead'],
          exclude: ['deadlift', 'row', 'curl', 'pull', 'lunge', 'squat'],
        );

        var backClean = _filterRelevant(
          backSeed,
          ['row', 'pull', 'lat', 'rear', 'face pull'],
          exclude: ['press', 'squat', 'push', 'leg', 'lunge', 'bench'],
        );

        var legClean = _filterRelevant(
          legsSeed,
          ['squat', 'deadlift', 'lunge', 'leg press', 'good morning'],
          exclude: ['bench', 'curl', 'push', 'press', 'row', 'pull', 'chest'],
        );

        // Guarantee minimum items
        chestClean = await _ensureAtLeast(
          chestClean,
          ['bench', 'press', 'push', 'chest', 'overhead'],
          exclude: ['deadlift', 'row', 'curl', 'pull', 'lunge', 'squat'],
          min: 6,
          extras: [
            ExerciseApi.search('incline bench press'),
            ExerciseApi.search('shoulder press'),
            ExerciseApi.search('dumbbell bench'),
            ExerciseApi.filter(bodyPart: 'chest'),
          ],
        );

        backClean = await _ensureAtLeast(
          backClean,
          ['row', 'pull', 'lat', 'rear', 'face pull'],
          exclude: ['press', 'squat', 'push', 'leg', 'lunge', 'bench'],
          min: 6,
          extras: [
            ExerciseApi.search('pull up'),
            ExerciseApi.search('lat pulldown'),
            ExerciseApi.search('seated row'),
            ExerciseApi.search('face pull'),
            ExerciseApi.filter(bodyPart: 'back'),
          ],
        );

        legClean = await _ensureAtLeast(
          legClean,
          ['squat', 'deadlift', 'lunge', 'leg press', 'good morning'],
          exclude: ['bench', 'curl', 'push', 'press', 'row', 'pull', 'chest'],
          min: 6,
          extras: [
            ExerciseApi.search('front squat'),
            ExerciseApi.search('romanian deadlift'),
            ExerciseApi.search('walking lunge'),
            ExerciseApi.search('leg press'),
            ExerciseApi.filter(bodyPart: 'upper legs'),
          ],
        );

        workouts.addAll([
          _buildWorkout(
            title: 'Push Day – Chest Focus',
            items: chestClean.take(8).toList(),
            category: cat,
            difficulty: WorkoutDifficulty.intermediate,
            description: 'Bench, incline, overhead pressing & push variations.',
          ),
          _buildWorkout(
            title: 'Pull Day – Back Focus',
            items: backClean.take(8).toList(),
            category: cat,
            difficulty: WorkoutDifficulty.intermediate,
            description: 'Rows, pulls, rear-delts & lat engagement.',
          ),
          _buildWorkout(
            title: 'Leg Day – Strength',
            items: legClean.take(8).toList(),
            category: cat,
            difficulty: WorkoutDifficulty.intermediate,
            description: 'Squats, hinges, lunges & machine leg work.',
          ),
        ]);
        break;
      }

      /* ---------- CARDIO ---------- */
      case WorkoutCategory.cardio: {
        final jump   = await ExerciseApi.search('jump rope');
        final run    = await ExerciseApi.search('run');
        final burpee = await ExerciseApi.search('burpee');
        final mtclim = await ExerciseApi.search('mountain climber');

        var hiitMix = _dedup(jump + burpee + mtclim);
        var hiitClean = _filterRelevant(
          hiitMix,
          ['jump', 'burpee', 'mountain', 'skipping', 'cardio', 'jack', 'high knees'],
          exclude: ['press', 'curl', 'row', 'squat', 'deadlift', 'bench'],
        );

        var runClean = _filterRelevant(
          run,
          ['run', 'sprint', 'jog'],
          exclude: ['press', 'curl', 'row', 'squat', 'deadlift', 'bench'],
        );

        // Guarantee minimums
        hiitClean = await _ensureAtLeast(
          hiitClean,
          ['jump', 'burpee', 'mountain', 'skipping', 'cardio', 'jack', 'high knees'],
          exclude: ['press', 'curl', 'row', 'squat', 'deadlift', 'bench'],
          min: 6,
          extras: [
            ExerciseApi.search('jumping jack'),
            ExerciseApi.search('high knees'),
            ExerciseApi.search('butt kicks'),
            ExerciseApi.search('skater jump'),
            ExerciseApi.filter(equipment: 'body weight'),
          ],
        );

        runClean = await _ensureAtLeast(
          runClean,
          ['run', 'sprint', 'jog'],
          exclude: ['press', 'curl', 'row', 'squat', 'deadlift', 'bench'],
          min: 6,
          extras: [
            ExerciseApi.search('running in place'),
            ExerciseApi.search('sprint drill'),
            ExerciseApi.search('treadmill run'),
            ExerciseApi.filter(bodyPart: 'lower legs'),
          ],
        );

        workouts.addAll([
          _buildWorkout(
            title: 'Cardio HIIT Blast',
            items: hiitClean.take(8).toList(),
            category: cat,
            difficulty: WorkoutDifficulty.advanced,
            description: 'Explosive cardio: burpees, jump rope, climbers, jacks.',
          ),
          _buildWorkout(
            title: 'Endurance Run',
            items: runClean.take(8).toList(),
            category: cat,
            difficulty: WorkoutDifficulty.beginner,
            description: 'Aerobic endurance & running mechanics.',
          ),
        ]);
        break;
      }

      /* ---------- YOGA ---------- */
      case WorkoutCategory.yoga: {
        final yoga    = await ExerciseApi.search('yoga');
        final stretch = await ExerciseApi.search('stretch');
        final balance = await ExerciseApi.search('balance');
        final pose    = await ExerciseApi.search('pose');

        final all = _dedup(yoga + stretch + balance + pose);

        var morning = _filterRelevant(
          all,
          ['pose', 'stretch', 'balance', 'downward', 'cobra', 'child', 'cat', 'cow'],
          exclude: ['press', 'row', 'deadlift', 'squat', 'curl', 'burpee'],
        );

        var balanceCore = _filterRelevant(
          all,
          ['balance', 'core', 'plank', 'warrior', 'tree', 'boat'],
          exclude: ['deadlift', 'squat', 'bench', 'row', 'burpee'],
        );

        var relax = _filterRelevant(
          all,
          ['relax', 'stretch', 'pose', 'breath', 'seated', 'supine', 'pigeon'],
          exclude: ['press', 'row', 'deadlift', 'squat', 'curl', 'burpee'],
        );

        // Guarantee minimums
        morning = await _ensureAtLeast(
          morning,
          ['pose', 'stretch', 'balance', 'downward', 'cobra', 'child', 'cat', 'cow'],
          exclude: ['press', 'row', 'deadlift', 'squat', 'curl', 'burpee'],
          min: 6,
          extras: [
            ExerciseApi.search('downward dog'),
            ExerciseApi.search('cobra pose'),
            ExerciseApi.search('child pose'),
            ExerciseApi.search('cat cow'),
          ],
        );

        balanceCore = await _ensureAtLeast(
          balanceCore,
          ['balance', 'core', 'plank', 'warrior', 'tree', 'boat'],
          exclude: ['deadlift', 'squat', 'bench', 'row', 'burpee'],
          min: 6,
          extras: [
            ExerciseApi.search('warrior pose'),
            ExerciseApi.search('tree pose'),
            ExerciseApi.search('boat pose'),
            ExerciseApi.search('side plank'),
          ],
        );

        relax = await _ensureAtLeast(
          relax,
          ['relax', 'stretch', 'pose', 'breath', 'seated', 'supine', 'pigeon'],
          exclude: ['press', 'row', 'deadlift', 'squat', 'curl', 'burpee'],
          min: 6,
          extras: [
            ExerciseApi.search('pigeon pose'),
            ExerciseApi.search('seated forward fold'),
            ExerciseApi.search('supine twist'),
            ExerciseApi.search('bridge pose'),
          ],
        );

        workouts.addAll([
          _buildWorkout(
            title: 'Morning Flow',
            items: morning.take(8).toList(),
            category: cat,
            difficulty: WorkoutDifficulty.beginner,
            description: 'Gentle sequence for mobility & energy.',
          ),
          _buildWorkout(
            title: 'Balance & Core Flow',
            items: balanceCore.take(8).toList(),
            category: cat,
            difficulty: WorkoutDifficulty.intermediate,
            description: 'Stability, posture & mindful control.',
          ),
          _buildWorkout(
            title: 'Evening Relaxation',
            items: relax.take(8).toList(),
            category: cat,
            difficulty: WorkoutDifficulty.beginner,
            description: 'Calming poses for recovery & stress relief.',
          ),
        ]);
        break;
      }

      /* ---------- HIIT ---------- */
      case WorkoutCategory.hiit: {
        final hiitMoves = await ExerciseApi.search('bodyweight hiit');
        var cleaned = _filterRelevant(
          hiitMoves,
          ['jump', 'plank', 'burpee', 'push', 'mountain', 'sprint', 'jack', 'lunge'],
          exclude: ['yoga', 'stretch', 'pose', 'bench', 'row', 'squat (hold)'],
        );

        // Guarantee minimums
        cleaned = await _ensureAtLeast(
          cleaned,
          ['jump', 'plank', 'burpee', 'push', 'mountain', 'sprint', 'jack', 'lunge'],
          exclude: ['yoga', 'stretch', 'pose', 'bench', 'row', 'squat (hold)'],
          min: 6,
          extras: [
            ExerciseApi.search('burpee'),
            ExerciseApi.search('squat jump'),
            ExerciseApi.search('plank jack'),
            ExerciseApi.search('lunge jump'),
            ExerciseApi.search('push up'),
            ExerciseApi.filter(equipment: 'body weight'),
          ],
        );

        workouts.add(_buildWorkout(
          title: 'Total Body HIIT',
          items: cleaned.take(8).toList(),
          category: cat,
          difficulty: WorkoutDifficulty.advanced,
          description: 'High-intensity intervals for full-body conditioning.',
        ));
        break;
      }

      /* ---------- CUSTOM ---------- */
      case WorkoutCategory.custom: {
        final tuple = await ExerciseApi.list(limit: 20, offset: 0);
        workouts.add(_buildWorkout(
          title: 'Custom Mix',
          items: _dedup(tuple.$1).take(8).toList(),
          category: cat,
          difficulty: WorkoutDifficulty.beginner,
          description: 'Mixed session using ExerciseDB base set.',
        ));
        break;
      }
    }

    final result = workouts.map((w) => w.copyWith(isFavorite: _fav(w.id))).toList();
    _cacheByCategory[categoryWire] = result;
    return result;
  }

  /* ------------ POPULAR FEED (stable featured) ------------ */
  Future<List<Workout>> getPopularWorkouts() async {
    await _loadFavorites();

    final pushups = await ExerciseApi.search('push up');
    final squats  = await ExerciseApi.search('squat');
    final burpees = await ExerciseApi.search('burpee');

    final featured = [
      _buildWorkout(
        title: 'Full Body Fat Burner',
        items: _dedup(pushups + squats + burpees).take(8).toList(),
        category: WorkoutCategory.hiit,
        difficulty: WorkoutDifficulty.advanced,
        description: 'Community favorite HIIT combo for fast calorie burn.',
      ),
      _buildWorkout(
        title: 'Strength Builder',
        items: _filterRelevant(squats, ['squat', 'lunge', 'deadlift']).take(8).toList(),
        category: WorkoutCategory.strength,
        difficulty: WorkoutDifficulty.intermediate,
        description: 'Compound lower-body session for strength & size.',
      ),
      _buildWorkout(
        title: 'Core & Balance Yoga',
        items: _filterRelevant(pushups, ['plank', 'balance', 'core', 'pose'],
            exclude: ['bench', 'row', 'deadlift', 'squat']).take(8).toList(),
        category: WorkoutCategory.yoga,
        difficulty: WorkoutDifficulty.beginner,
        description: 'Gentle flow focused on posture & core control.',
      ),
    ];

    return featured.map((w) => w.copyWith(isFavorite: _fav(w.id))).toList();
  }

  /* ------------ FAVORITES + UTILITIES ------------ */

  Future<List<Workout>> getFavoriteWorkouts() async {
    if (_db == null || userId == null) return [];
    await _loadFavorites();
    final all = await getWorkouts();
    return all.where((w) => _favoriteIds.contains(w.id)).toList();
  }

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

    _cacheAll = null;
    _cacheByCategory.clear();
  }

  /* ------------ SEARCH UTILITIES (pass-through) ------------ */

  Future<List<Exercise>> searchExercises(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    return ExerciseApi.search(q);
  }

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

  Future<Workout?> searchToWorkout(String q) async {
    final hits = await searchExercises(q);
    if (hits.isEmpty) return null;
    return buildInstantWorkout(title: q, items: _dedup(hits).take(8).toList());
  }
}
