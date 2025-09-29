// Your existing models, enhanced with toMap/fromMap + enum helpers

enum WorkoutCategory {
  strength('Strength Training', '💪', wire: 'strength'),
  cardio('Cardio', '🏃‍♂️', wire: 'cardio'),
  yoga('Yoga & Flexibility', '🧘‍♀️', wire: 'yoga'),
  hiit('HIIT', '🔥', wire: 'hiit'),
  custom('Custom', '⭐', wire: 'custom');

  final String name;
  final String emoji;
  final String wire;
  const WorkoutCategory(this.name, this.emoji, {required this.wire});

  static WorkoutCategory fromWire(String? v) =>
      WorkoutCategory.values.firstWhere(
        (e) => e.wire == (v ?? '').toLowerCase(),
        orElse: () => WorkoutCategory.custom,
      );
}

enum WorkoutDifficulty {
  beginner('Beginner', wire: 'beginner'),
  intermediate('Intermediate', wire: 'intermediate'),
  advanced('Advanced', wire: 'advanced');

  final String name;
  final String wire;
  const WorkoutDifficulty(this.name, {required this.wire});

  static WorkoutDifficulty fromWire(String? v) =>
      WorkoutDifficulty.values.firstWhere(
        (e) => e.wire == (v ?? '').toLowerCase(),
        orElse: () => WorkoutDifficulty.beginner,
      );
}

class Workout {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String duration;   // e.g. "45m" or "00:45:00"
  final int calories;
  final String difficulty; // keep as string (wire)
  final List<WorkoutExercise> exercises;
  final bool isFavorite;
  final String category;   // keep as string (wire)
  final String equipment;
  final String focusArea;

  const Workout({
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

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'duration': duration,
        'calories': calories,
        'difficulty': difficulty,
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'isFavorite': isFavorite,
        'category': category,
        'equipment': equipment,
        'focusArea': focusArea,
      };

  factory Workout.fromMap(Map<String, dynamic> m) => Workout(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        description: (m['description'] ?? '').toString(),
        imageUrl: (m['imageUrl'] ?? '').toString(),
        duration: (m['duration'] ?? '0m').toString(),
        calories: (m['calories'] ?? 0) is int ? m['calories'] as int : int.tryParse('${m['calories']}') ?? 0,
        difficulty: (m['difficulty'] ?? 'beginner').toString(),
        exercises: (m['exercises'] as List? ?? [])
            .map((e) => WorkoutExercise.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        isFavorite: (m['isFavorite'] ?? false) == true,
        category: (m['category'] ?? 'custom').toString(),
        equipment: (m['equipment'] ?? '').toString(),
        focusArea: (m['focusArea'] ?? '').toString(),
      );

  WorkoutDifficulty get difficultyEnum => WorkoutDifficulty.fromWire(difficulty);
  WorkoutCategory get categoryEnum => WorkoutCategory.fromWire(category);
}

class WorkoutExercise {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String videoUrl;
  final String duration; // optional per-exercise time (e.g., "45s")
  final int sets;
  final int reps;
  final String restTime; // e.g. "90s" or "1:30"

  const WorkoutExercise({
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

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'duration': duration,
        'sets': sets,
        'reps': reps,
        'restTime': restTime,
      };

  factory WorkoutExercise.fromMap(Map<String, dynamic> m) => WorkoutExercise(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        description: (m['description'] ?? '').toString(),
        imageUrl: (m['imageUrl'] ?? '').toString(),
        videoUrl: (m['videoUrl'] ?? '').toString(),
        duration: (m['duration'] ?? '').toString(),
        sets: (m['sets'] ?? 0) is int ? m['sets'] as int : int.tryParse('${m['sets']}') ?? 0,
        reps: (m['reps'] ?? 0) is int ? m['reps'] as int : int.tryParse('${m['reps']}') ?? 0,
        restTime: (m['restTime'] ?? '60s').toString(),
      );
}
