import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/models/workout_model.dart';
import 'package:fitness_flex_app/presentation/pages/workout_player_page.dart';

class WorkoutDetailPage extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailPage({super.key, required this.workout});

  bool _isUrl(String s) => s.startsWith('http://') || s.startsWith('https://');

  Color _difficultyColor(String difficulty, BuildContext context) {
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

  Widget _heroMedia(BuildContext context, String urlOrEmoji) {
    final bg = Theme.of(context).colorScheme.primary.withOpacity(0.2);
    if (_isUrl(urlOrEmoji)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(urlOrEmoji, width: 140, height: 140, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Center(child: Text(urlOrEmoji, style: const TextStyle(fontSize: 48))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(workout.difficulty, context);

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.title),
        actions: [
          IconButton(
            icon: Icon(
              workout.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: workout.isFavorite ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: () {
              // Hook to repo.toggleFavorite(workout.id) if desired
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Favorite toggle not wired on detail page')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Center(child: _heroMedia(context, workout.imageUrl)),
            const SizedBox(height: 20),

            // Title + category
            Center(
              child: Column(
                children: [
                  Text(
                    workout.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    workout.category,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Description
            if (workout.description.isNotEmpty) ...[
              Text(
                workout.description,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statChip(context, Icons.access_time, workout.duration),
                _statChip(context, Icons.local_fire_department, '${workout.calories} cal'),
                Chip(
                  backgroundColor: diffColor.withOpacity(0.15),
                  label: Text(
                    workout.difficulty[0].toUpperCase() + workout.difficulty.substring(1),
                    style: TextStyle(color: diffColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Exercises list
            const Text('Exercises', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Column(
              children: List.generate(workout.exercises.length, (i) {
                final e = workout.exercises[i];
                return _exerciseTile(context, e, index: i);
              }),
            ),

            const SizedBox(height: 30),

            // Quick start button (starts from first exercise)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutPlayerPage(
                      workout: workout,
                      initialExerciseIndex: 0,
                    ),
                  ),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Workout'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(BuildContext context, IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      label: Text(text, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600)),
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _exerciseTile(BuildContext context, WorkoutExercise e, {required int index}) {
    Widget leading;
    if (_isUrl(e.imageUrl)) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.network(e.imageUrl, width: 44, height: 44, fit: BoxFit.cover),
      );
    } else {
      leading = CircleAvatar(
        radius: 22,
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        child: const Icon(Icons.fitness_center, color: Colors.black54),
      );
    }

    final subtitle = StringBuffer();
    if (e.description.isNotEmpty) {
      final d = e.description.length > 120 ? '${e.description.substring(0, 120)}…' : e.description;
      subtitle.writeln(d);
    }
    subtitle.write(
      '${e.sets} sets × ${e.reps} reps  •  Rest ${e.restTime}'
      '${e.duration.isNotEmpty ? '  •  ${e.duration}' : ''}',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutPlayerPage(
                workout: workout,
                initialExerciseIndex: index, // start the player on this exercise
              ),
            ),
          );
        },
        leading: leading,
        title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle.toString()),
        trailing: const Icon(Icons.play_circle_fill),
      ),
    );
  }
}
