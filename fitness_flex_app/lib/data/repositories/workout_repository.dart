import 'package:fitness_flex_app/data/models/workout_model.dart';

class WorkoutRepository {
  // Sample workout data - in a real app, this would come from an API
  final List<WorkoutCategory> categories = [
    WorkoutCategory(
      id: '1',
      name: 'Strength Training',
      imageUrl: '💪',
      workoutCount: 12,
    ),
    WorkoutCategory(
      id: '2',
      name: 'Cardio',
      imageUrl: '🏃‍♂️',
      workoutCount: 8,
    ),
    WorkoutCategory(
      id: '3',
      name: 'Yoga & Flexibility',
      imageUrl: '🧘‍♀️',
      workoutCount: 6,
    ),
    WorkoutCategory(id: '4', name: 'HIIT', imageUrl: '🔥', workoutCount: 10),
  ];

  final List<Workout> workouts = [
    Workout(
      id: '1',
      title: 'Full Body Strength',
      description:
          'Complete full body workout targeting all major muscle groups',
      imageUrl: '🏋️‍♂️',
      duration: '45 min',
      calories: 320,
      difficulty: 'Intermediate',
      exercises: [
        WorkoutExercise(
          id: '1',
          name: 'Bench Press',
          description: 'Chest exercise using barbell',
          imageUrl: '📸',
          videoUrl: '',
          duration: '4 sets',
          sets: 4,
          reps: 10,
          restTime: '60s',
        ),
        WorkoutExercise(
          id: '2',
          name: 'Squats',
          description: 'Leg exercise with barbell',
          imageUrl: '📸',
          videoUrl: '',
          duration: '4 sets',
          sets: 4,
          reps: 12,
          restTime: '60s',
        ),
        WorkoutExercise(
          id: '3',
          name: 'Pull-ups',
          description: 'Back exercise using bodyweight',
          imageUrl: '📸',
          videoUrl: '',
          duration: '3 sets',
          sets: 3,
          reps: 8,
          restTime: '45s',
        ),
      ],
    ),
    Workout(
      id: '2',
      title: 'Morning Yoga Flow',
      description: 'Gentle yoga routine to start your day',
      imageUrl: '🧘‍♀️',
      duration: '30 min',
      calories: 180,
      difficulty: 'Beginner',
      exercises: [
        WorkoutExercise(
          id: '1',
          name: 'Sun Salutations',
          description: 'Sequence of yoga poses',
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
          description: 'Strength building poses',
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
      description: 'High intensity interval training for maximum calorie burn',
      imageUrl: '🔥',
      duration: '25 min',
      calories: 280,
      difficulty: 'Advanced',
      exercises: [
        WorkoutExercise(
          id: '1',
          name: 'Jumping Jacks',
          description: 'Full body cardio exercise',
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
          description: 'Full body explosive movement',
          imageUrl: '📸',
          videoUrl: '',
          duration: '45s on, 15s off',
          sets: 1,
          reps: 1,
          restTime: '15s',
        ),
      ],
    ),
  ];

  Future<List<WorkoutCategory>> getCategories() async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay
    return categories;
  }

  Future<List<Workout>> getWorkouts() async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay
    return workouts;
  }

  Future<List<Workout>> getWorkoutsByCategory(String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return workouts;
  }

  Future<List<Workout>> getFavoriteWorkouts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return workouts.where((workout) => workout.isFavorite).toList();
  }

  Future<void> toggleFavorite(String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // In a real app, this would update the database
  }
}
