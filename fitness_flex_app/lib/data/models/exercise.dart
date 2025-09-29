// Normalized Exercise model (adapter for ExerciseDB v1 responses)

class Exercise {
  final String id, name, bodyPart, equipment, gifUrl;
  final List<String> instructions;

  Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.equipment,
    required this.gifUrl,
    this.instructions = const [],
  });

  /// Map ExerciseDB v1 item -> Exercise (our canonical shape)
  factory Exercise.fromExDb(Map<String, dynamic> j) {
    String first(dynamic v, [String fallback = '']) {
      if (v is List && v.isNotEmpty) return v.first.toString();
      if (v is String) return v;
      return fallback;
    }
    return Exercise(
      id: (j['exerciseId'] ?? j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      bodyPart: first(j['bodyParts'] ?? j['bodyPart']),
      equipment: first(j['equipments'] ?? j['equipment']),
      gifUrl: (j['gifUrl'] ?? j['gif'] ?? '').toString(),
      instructions: (j['instructions'] is List)
          ? List<String>.from((j['instructions'] as List).map((e) => e.toString()))
          : const [],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'bodyPart': bodyPart,
        'equipment': equipment,
        'gifUrl': gifUrl,
        'instructions': instructions,
      };

  factory Exercise.fromMap(Map<String, dynamic> m) => Exercise(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        bodyPart: (m['bodyPart'] ?? '').toString(),
        equipment: (m['equipment'] ?? '').toString(),
        gifUrl: (m['gifUrl'] ?? '').toString(),
        instructions: (m['instructions'] is List)
            ? List<String>.from((m['instructions'] as List).map((e) => e.toString()))
            : const [],
      );
}
