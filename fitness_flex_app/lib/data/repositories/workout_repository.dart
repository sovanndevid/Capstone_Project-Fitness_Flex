import 'package:fitness_flex_app/data/models/workout_model.dart';

class WorkoutRepository {
  final List<WorkoutCategory> categories = [
    WorkoutCategory.strength,
    WorkoutCategory.cardio,
    WorkoutCategory.yoga,
    WorkoutCategory.hiit,
  ];

  final List<Workout> workouts = [
    Workout(
      id: '1',
      title: 'Full Body Strength',
      description: 'Complete full body workout targeting all major muscle groups with compound exercises',
      imageUrl: '💪',
      duration: '45 min',
      calories: 320,
      difficulty: 'Intermediate',
      category: 'Strength Training',
      equipment: 'Dumbbells, Bench',
      focusArea: 'Full Body',
      exercises: [
        WorkoutExercise(
          id: '1',
          name: 'Bench Press',
          description: 'Chest exercise using barbell - 3 sets of 10 reps',
          imageUrl: '📸',
          videoUrl: '',
          duration: '15 min',
          sets: 3,
          reps: 10,
          restTime: '60s',
        ),
        WorkoutExercise(
          id: '2',
          name: 'Squats',
          description: 'Leg exercise with barbell - 4 sets of 12 reps',
          imageUrl: '📸',
          videoUrl: '',
          duration: '20 min',
          sets: 4,
          reps: 12,
          restTime: '60s',
        ),
        WorkoutExercise(
          id: '3',
          name: 'Pull-ups',
          description: 'Back exercise using bodyweight - 3 sets to failure',
          imageUrl: '📸',
          videoUrl: '',
          duration: '10 min',
          sets: 3,
          reps: 8,
          restTime: '45s',
        ),
      ],
    ),
    Workout(
      id: '2',
      title: 'Morning Yoga Flow',
      description: 'Gentle yoga routine to start your day with stretching and breathing',
      imageUrl: '🧘‍♀️',
      duration: '30 min',
      calories: 180,
      difficulty: 'Beginner',
      category: 'Yoga & Flexibility',
      equipment: 'Yoga Mat',
      focusArea: 'Full Body',
      exercises: [
        WorkoutExercise(
          id: '1',
          name: 'Sun Salutations',
          description: 'Sequence of yoga poses for warm-up',
          imageUrl: '📸',
          videoUrl: '',
          duration: '5 min',
          sets: 1,
          reps: 12,
          restTime: '0s',
        ),
        WorkoutExercise(
          id: '2',
          name: 'Warrior Poses',
          description: 'Strength building yoga poses',
          imageUrl: '📸',
          videoUrl: '',
          duration: '10 min',
          sets: 1,
          reps: 3,
          restTime: '15s',
        ),
      ],
    ),
    Workout(
      id: '3',
      title: 'HIIT Cardio Blast',
      description: 'High intensity interval training for maximum calorie burn and endurance',
      imageUrl: '🔥',
      duration: '25 min',
      calories: 280,
      difficulty: 'Advanced',
      category: 'HIIT',
      equipment: 'None',
      focusArea: 'Cardio',
      exercises: [
        WorkoutExercise(
          id: '1',
          name: 'Jumping Jacks',
          description: 'Full body cardio exercise - 45s work, 15s rest',
          imageUrl: '📸',
          videoUrl: '',
          duration: '45s on, 15s off',
          sets: 1,
          reps: 1,
          restTime: '15s',
        ),
        WorkoutExercise(
          id: '2',
          name: 'Burpees',
          description: 'Full body explosive movement - 45s work, 15s rest',
          imageUrl: '📸',
          videoUrl: '',
          duration: '45s on, 15s off',
          sets: 1,
          reps: 1,
          restTime: '15s',
        ),
      ],
    ),
    Workout(
      id: '4',
      title: 'Upper Body Sculpt',
      description: 'Focus on chest, back, shoulders, and arms for definition',
      imageUrl: '💪',
      duration: '50 min',
      calories: 380,
      difficulty: 'Intermediate',
      category: 'Strength Training',
      equipment: 'Dumbbells, Bench',
      focusArea: 'Upper Body',
      exercises: [
        WorkoutExercise(
          id: '1',
          name: 'Dumbbell Press',
          description: 'Chest exercise - 4 sets of 12 reps',
          imageUrl: '📸',
          videoUrl: '',
          duration: '20 min',
          sets: 4,
          reps: 12,
          restTime: '60s',
        ),
      ],
    ),
  ];

  Future<List<WorkoutCategory>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return categories;
  }

  Future<List<Workout>> getWorkouts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return workouts;
  }

  Future<List<Workout>> getWorkoutsByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return workouts.where((workout) => workout.category == category).toList();
  }

  Future<List<Workout>> getFavoriteWorkouts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return workouts.where((workout) => workout.isFavorite).toList();
  }

  Future<void> toggleFavorite(String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // In a real app, this would update the database
  }

  Future<List<Workout>> getPopularWorkouts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Return first 3 workouts as popular
    return workouts.take(3).toList();
  }
}
