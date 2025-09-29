import '../models/exercise.dart';
import '../models/workout_model.dart';
import '../models/workout_builder.dart';
import '../models/exercise_api.dart';

const presetCatalog = [
  {
    'key': 'full_body_beginner',
    'title': 'Full Body (Beginner)',
    'description': 'Total-body routine with basic movements.',
    'category': 'strength',
    'difficulty': 'beginner',
    'items': [
      {'name':'Goblet Squat','sets':3,'reps':12,'rest':'60s'},
      {'name':'Dumbbell Bench Press','sets':3,'reps':10,'rest':'60s'},
      {'name':'One Arm Dumbbell Row','sets':3,'reps':10,'rest':'60s'},
    ]
  },
  {
    'key': 'push_day_hypertrophy',
    'title': 'Push Day – Hypertrophy',
    'description': 'Chest/shoulders/triceps emphasis.',
    'category': 'strength',
    'difficulty': 'intermediate',
    'items': [
      {'name':'Barbell Bench Press','sets':4,'reps':8,'rest':'120s'},
      {'name':'Incline Dumbbell Press','sets':3,'reps':10,'rest':'90s'},
      {'name':'Standing Barbell Shoulder Press','sets':3,'reps':8,'rest':'120s'},
    ]
  },
];

WorkoutCategory _cat(String w) => WorkoutCategory.fromWire(w);
WorkoutDifficulty _dif(String w) => WorkoutDifficulty.fromWire(w);

Future<Workout> buildPresetWorkout(String key) async {
  final p = presetCatalog.firstWhere((x) => x['key'] == key);

  // Resolve names -> ExerciseDB hits
  final resolved = <Exercise>[];
  for (final it in (p['items'] as List)) {
    final name = (it['name'] as String);
    final results = await ExerciseApi.search(name);
    if (results.isNotEmpty) resolved.add(results.first);
  }

  return WorkoutBuilder.fromExercises(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: p['title'] as String,
    description: p['description'] as String,
    imageUrl: resolved.isNotEmpty ? resolved.first.gifUrl : '',
    items: resolved,
    category: _cat(p['category'] as String),
    difficulty: _dif(p['difficulty'] as String),
  );
}
