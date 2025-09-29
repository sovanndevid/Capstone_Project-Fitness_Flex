import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/models/workout_model.dart';
import 'package:fitness_flex_app/data/repositories/workout_repository.dart';
import 'package:fitness_flex_app/presentation/pages/workout_detail_page.dart';

class WorkoutCategoryPage extends StatefulWidget {
  final WorkoutRepository workoutRepository;
  final WorkoutCategory category; // ✅ enum, not String

  const WorkoutCategoryPage({
    super.key,
    required this.workoutRepository,
    required this.category,
  });

  @override
  State<WorkoutCategoryPage> createState() => _WorkoutCategoryPageState();
}

class _WorkoutCategoryPageState extends State<WorkoutCategoryPage> {
  late Future<List<Workout>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // ✅ use the enum's stable wire key
    _future = widget.workoutRepository.getWorkoutsByCategory(widget.category.wire);
  }

  void _refresh() => setState(_load);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Pretty title with emoji + display name
        title: Text('${widget.category.emoji} ${widget.category.name}'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
      ),
      body: FutureBuilder<List<Workout>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final workouts = snapshot.data ?? const <Workout>[];
          if (workouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No workouts found in ${widget.category.name}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutDetailPage(workout: workout),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Icon / cover
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(workout.imageUrl, style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Texts
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(workout.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    )),
                                const SizedBox(height: 4),
                                Text(
                                  '${workout.duration} • ${workout.calories} cal',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),

                          // Difficulty pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _difficultyColor(workout.difficulty),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              workout.difficulty,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
