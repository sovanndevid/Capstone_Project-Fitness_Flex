class Workout {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String duration;
  final int calories;
  final String difficulty;
  final List<WorkoutExercise> exercises;
  final bool isFavorite;

  Workout({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.duration,
    required this.calories,
    required this.difficulty,
    required this.exercises,
    this.isFavorite = false,
  });

  Workout copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? duration,
    int? calories,
    String? difficulty,
    List<WorkoutExercise>? exercises,
    bool? isFavorite,
  }) {
    return Workout(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      duration: duration ?? this.duration,
      calories: calories ?? this.calories,
      difficulty: difficulty ?? this.difficulty,
      exercises: exercises ?? this.exercises,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class WorkoutExercise {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String videoUrl;
  final String duration;
  final int sets;
  final int reps;
  final String restTime;

  WorkoutExercise({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.videoUrl,
    required this.duration,
    required this.sets,
    required this.reps,
    required this.restTime,
  });
}

class WorkoutCategory {
  final String id;
  final String name;
  final String imageUrl;
  final int workoutCount;

  WorkoutCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.workoutCount,
  });
}
