import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/models/workout_model.dart';
import 'package:fitness_flex_app/data/repositories/workout_repository.dart';
import 'package:fitness_flex_app/presentation/pages/workout_detail_page.dart';
import 'package:fitness_flex_app/presentation/pages/workout_category_page.dart';
import 'package:fitness_flex_app/presentation/pages/workout_player_page.dart';
import 'package:fitness_flex_app/presentation/pages/workout_search_page.dart';
import 'package:fitness_flex_app/data/models/workout_log.dart';
import 'package:fitness_flex_app/data/repositories/workout_log_repository.dart';

class WorkoutListPage extends StatefulWidget {
  const WorkoutListPage({super.key});

  @override
  State<WorkoutListPage> createState() => _WorkoutListPageState();
}

class _WorkoutListPageState extends State<WorkoutListPage> {
  final WorkoutRepository _workoutRepository = WorkoutRepository();
  late Future<List<WorkoutCategory>> _categoriesFuture;
  late Future<List<Workout>> _popularWorkoutsFuture;
  final WorkoutLogRepository _workoutLogRepository = WorkoutLogRepository();
  late Future<List<WorkoutLog>> _todayLogsFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _workoutRepository.getCategories();
    _popularWorkoutsFuture = _workoutRepository.getPopularWorkouts();
    _todayLogsFuture = _workoutLogRepository.getTodayLogs();
  }

  void _refreshData() {
    setState(() {
      _categoriesFuture = _workoutRepository.getCategories();
      _popularWorkoutsFuture = _workoutRepository.getPopularWorkouts();
      _todayLogsFuture = _workoutLogRepository.getTodayLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutSearchPage(repo: _workoutRepository),
                ),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Work out done today',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTodayDoneSection(),
              const SizedBox(height: 24),

              const Text(
                'Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildCategoriesSection(),
              const SizedBox(height: 24),

              const Text(
                'Popular Workouts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPopularWorkoutsSection(),
              const SizedBox(height: 24),

              const Text(
                'All Workouts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildAllWorkoutsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayDoneSection() {
    return StreamBuilder<List<WorkoutLog>>(
      stream: _workoutLogRepository.streamTodayLogs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 56,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final logs = snapshot.data!;
        if (logs.isEmpty) {
          return const Text('No workouts completed today yet.');
        }
        return Column(
          children: logs.map((log) {
            final time = TimeOfDay.fromDateTime(log.completedAt).format(context);
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(log.title),
              subtitle: Text('Completed at $time'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (log.duration > 0) Text('${log.duration} min  '),
                  if (log.calories > 0)
                    Row(children: [const Icon(Icons.local_fire_department, size: 16), Text(' ${log.calories}')]),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCategoriesSection() {
    return FutureBuilder<List<WorkoutCategory>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 112,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Categories error: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }

        final categories = snapshot.data!;
        return SizedBox(
          height: 112, // <- a touch taller than 100 to avoid tiny overflows
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final c = categories[index];
              return _CategoryCard(
                emoji: c.emoji,
                label: c.name,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutCategoryPage(
                        workoutRepository: _workoutRepository,
                        category: c,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPopularWorkoutsSection() {
    return FutureBuilder<List<Workout>>(
      future: _popularWorkoutsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Popular error: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }

        final workouts = snapshot.data!;
        if (workouts.isEmpty) {
          return const Text('No popular workouts yet.');
        }

        return SizedBox(
          height: 260, // was 230; extra room avoids overflow
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: workouts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final w = workouts[index];
              return SizedBox(
                width: 280,
                child: _workoutCard(context, w, isPopular: true),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAllWorkoutsSection() {
    return FutureBuilder<List<Workout>>(
      future: _workoutRepository.getWorkouts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(
            'All workouts error: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }

        final workouts = snapshot.data!;
        return Column(
          children: workouts
              .map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _workoutCard(context, w, isPopular: false),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _workoutCard(
    BuildContext context,
    Workout workout, {
    required bool isPopular,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutDetailPage(workout: workout),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        workout.imageUrl.isNotEmpty
                            ? workout.imageUrl.characters.first
                            : '🏋️',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          workout.category,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      workout.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: workout.isFavorite
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    onPressed: () {
                      // hook up repo.toggleFavorite(workout.id) if you want here
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                workout.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat(Icons.access_time, workout.duration),
                  _stat(Icons.local_fire_department, '${workout.calories} cal'),
                  _stat(Icons.bar_chart, workout.difficulty),
                ],
              ),
              if (isPopular) ...[
                const SizedBox(height: 6), // was 12
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.25)),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6), // was 8
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Mark done'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: const VisualDensity(horizontal: -2, vertical: -4),
                    ),
                    onPressed: () async {
                      try {
                        await _workoutLogRepository.logWorkout(workout);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Logged "${workout.title}"')),
                        );
                        // No setState needed; the StreamBuilder above will refresh.
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 128, // a little wider helps long labels
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
