import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/models/workout_model.dart';
import 'package:fitness_flex_app/data/repositories/workout_repository.dart';
import 'package:fitness_flex_app/presentation/pages/workout_detail_page.dart';
import 'package:fitness_flex_app/presentation/pages/workout_category_page.dart';
import 'package:fitness_flex_app/presentation/pages/workout_search_page.dart';
import 'package:fitness_flex_app/data/models/workout_log.dart';
import 'package:fitness_flex_app/data/repositories/workout_log_repository.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';
import 'package:fitness_flex_app/core/themes/app_theme.dart';

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
  int _selectedIndex = 1;
  final Set<String> _favoriteWorkoutTitles = {}; // added in-memory favorites

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

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRouter.home);
        break;
      case 1:
        // already here
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRouter.nutrition);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRouter.progress);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectionTitleStyle = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: .2,
      color: Colors.black, // forced black
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Workouts',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black, // forced black
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutSearchPage(repo: _workoutRepository),
                ),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.black87), onPressed: _refreshData),
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
              Text('Work out done today', style: sectionTitleStyle),
              const SizedBox(height: 10),
              _buildTodayDoneSection(),
              const SizedBox(height: 24),

              Text('Categories', style: sectionTitleStyle),
              const SizedBox(height: 12),
              _buildCategoriesSection(),
              const SizedBox(height: 24),

              Text('Popular Workouts', style: sectionTitleStyle),
              const SizedBox(height: 12),
              _buildPopularWorkoutsSection(),
              const SizedBox(height: 24),

              Text('All Workouts', style: sectionTitleStyle),
              const SizedBox(height: 12),
              _buildAllWorkoutsSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
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
            final time = TimeOfDay.fromDateTime(
              log.completedAt,
            ).format(context);
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
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department, size: 16),
                        Text(' ${log.calories}'),
                      ],
                    ),
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
    final primary = Theme.of(context).colorScheme.primary;
    final isFav = _favoriteWorkoutTitles.contains(workout.title) || (workout.isFavorite == true);

    return Card(
      elevation: 1,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.black.withOpacity(.04)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutDetailPage(workout: workout),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3F7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black.withOpacity(.05)),
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
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black, // forced black
                          ),
                        ),
                        Text(
                          workout.category,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      size: 22,
                      color: isFav ? primary : Colors.grey[500],
                    ),
                    splashRadius: 20,
                    onPressed: () {
                      setState(() {
                        if (isFav) {
                          _favoriteWorkoutTitles.remove(workout.title);
                        } else {
                          _favoriteWorkoutTitles.add(workout.title);
                        }
                      });

                      // Optional: persist if a method exists:
                      // _workoutRepository.toggleFavorite(workout);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                workout.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.25),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _stat(Icons.access_time, workout.duration),
                  _stat(Icons.local_fire_department, '${workout.calories} cal'),
                  _stat(Icons.bar_chart, workout.difficulty),
                ],
              ),
              if (isPopular) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .5,
                      color: Colors.orange, // unchanged accent
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Mark done'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withOpacity(.35)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                ),
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
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primary,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
