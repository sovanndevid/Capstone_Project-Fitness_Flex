import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/models/workout_model.dart';

class WorkoutDetailPage extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailPage({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(workout.title),
        actions: [
          IconButton(
            icon: Icon(
              workout.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: workout.isFavorite
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () {
              // Toggle favorite
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workout Header
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    workout.imageUrl,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: Text(
                workout.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Center(
              child: Text(
                workout.description,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // Workout Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, Icons.access_time, workout.duration),
                _buildStatItem(
                  context,
                  Icons.local_fire_department,
                  '${workout.calories} cal',
                ),
                _buildStatItem(context, Icons.bar_chart, workout.difficulty),
              ],
            ),
            const SizedBox(height: 30),

            // Exercises List
            const Text(
              'Exercises',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Column(
              children: workout.exercises.map((exercise) {
                return _buildExerciseItem(context, exercise);
              }).toList(),
            ),
            const SizedBox(height: 30),

            // Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Start workout functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Starting ${workout.title}...'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  // You can navigate to a workout tracking page here
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Workout',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildExerciseItem(BuildContext context, WorkoutExercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.2),
          child: const Icon(Icons.fitness_center, color: Colors.black54),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(exercise.description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              exercise.duration,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${exercise.sets} sets × ${exercise.reps} reps',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void someFunction(BuildContext context) {
    Navigator.pop(context);
  }
}
