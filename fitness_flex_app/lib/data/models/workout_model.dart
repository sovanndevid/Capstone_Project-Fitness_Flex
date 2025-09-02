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
  final String category;
  final String equipment;
  final String focusArea;

  Workout({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.duration,
    required this.calories,
    required this.difficulty,
    required this.exercises,
    required this.category,
    required this.equipment,
    required this.focusArea,
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
    String? category,
    String? equipment,
    String? focusArea,
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
      category: category ?? this.category,
      equipment: equipment ?? this.equipment,
      focusArea: focusArea ?? this.focusArea,
    );
  }

  // Add toMap and fromMap methods if needed
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

// Use this enum everywhere in your code!
enum WorkoutCategory {
  strength('Strength Training', '💪'),
  cardio('Cardio', '🏃‍♂️'),
  yoga('Yoga & Flexibility', '🧘‍♀️'),
  hiit('HIIT', '🔥'),
  custom('Custom', '⭐');

  final String name;
  final String emoji;
  const WorkoutCategory(this.name, this.emoji);
}

enum WorkoutDifficulty {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced');

  final String name;
  const WorkoutDifficulty(this.name);
}
