import 'package:flutter/material.dart';
import 'dart:async'; // <— Added for Timer
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
  final Set<String> _favoriteWorkoutTitles = {};
  final TextEditingController _searchController = TextEditingController(); // <— added

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sectionTitleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: .2,
      color: Colors.black,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Workouts',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FA), Color(0xFFEFF3F7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            _refreshData();
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WorkoutHeroSlider(),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 22),

                // Categories
                _SectionCard(
                  title: 'Categories',
                  child: _buildCategoriesSection(),
                ),
                const SizedBox(height: 18),

                // Popular
                _SectionCard(
                  title: 'Popular Workouts',
                  child: _buildPopularWorkoutsSection(),
                ),
                const SizedBox(height: 18),

                const Text('All Workouts', style: sectionTitleStyle),
                const SizedBox(height: 10),
                _buildAllWorkoutsSection(),
                const SizedBox(height: 26),

                // Moved to bottom
                _SectionCard(
                  title: 'Work out done today',
                  child: _buildTodayDoneSection(),
                ),
              ],
            ),
          ),
        ),
      ),
bottomNavigationBar: NavigationBar(
  selectedIndex: 1, // <-- Workouts is index 1
  onDestinationSelected: (index) {
    if (index == 1) return; // already here
    switch (index) {
      case 0: Navigator.pushReplacementNamed(context, AppRouter.home); break;
      case 1: /* current page */ break;
      case 2: Navigator.pushReplacementNamed(context, AppRouter.nutrition); break;
      case 3: Navigator.pushReplacementNamed(context, AppRouter.progress); break;
      case 4: Navigator.pushReplacementNamed(context, AppRouter.profile); break;
    }
  },
  destinations: const [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Workouts'),
    NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Nutrition'),
    NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Progress'),
    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
  ],
),
    );
  } 
  /* ---------- Sections ---------- */

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
          return Text(
            'No workouts completed today yet.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          );
        }
        return Column(
          children: logs.map((log) {
            final time = TimeOfDay.fromDateTime(log.completedAt).format(context);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14.5)),
                        const SizedBox(height: 2),
                        Text('Completed at $time',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                  if (log.duration > 0)
                    _tinyChip(Icons.access_time, '${log.duration}m'),
                  const SizedBox(width: 8),
                  if (log.calories > 0)
                    _tinyChip(Icons.local_fire_department, '${log.calories}'),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Helper to map category name -> image asset
  String _categoryImage(String name) {
    final n = name.toLowerCase().trim();
    if (n.contains('strength')) return 'assets/images/strength.jpg';
    if (n.contains('cardio')) return 'assets/images/cardio.jpg';
    if (n.contains('yoga')) return 'assets/images/yoga.jpg';
    if (n.contains('flex')) return 'assets/images/yoga.jpg';
    if (n == 'hit' || n == 'hiit' || n.contains('hit')) return 'assets/images/HIT.jpg';
    if (n.contains('costume') || n.contains('custom')) return 'assets/images/costume.jpg';
    return 'assets/images/strength.jpg';
  }

  Widget _buildCategoriesSection() {
    return FutureBuilder<List<WorkoutCategory>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Categories error: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }
        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return Text(
            'No categories found.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          );
        }

        // Pre-cache images
        for (final c in categories) {
          precacheImage(AssetImage(_categoryImage(c.name)), context);
        }

        // 5 x 1 (five rows, one per full-width card)
        return Column(
          children: [
            for (final c in categories)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _WideCategoryCard(
                  label: c.name,
                  imagePath: _categoryImage(c.name),
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
                ),
              ),
          ],
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
          height: 260, // <- was 210; match card's real height needs
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
        return Text(
          'No popular workouts yet.',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        );
      }

      return SizedBox(
        height: 280,// <- was 210; prevents "overflowed by 49–53 px" errors
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

  /* ---------- Card ---------- */

  Widget _workoutCard(
    BuildContext context,
    Workout workout, {
    required bool isPopular,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    final isFav = _favoriteWorkoutTitles.contains(workout.title) ||
        (workout.isFavorite == true);

    return Card(
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.black.withOpacity(.05)),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          workout.category,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
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
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                workout.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.grey[700],
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),

              // Wrap avoids any horizontal overflow on smaller screens.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _statChip(Icons.access_time, workout.duration),
                  _statChip(Icons.local_fire_department, '${workout.calories} cal'),
                  _pillChip(
                    _difficultyLabel(workout.difficulty),
                    _difficultyColor(_difficultyLabel(workout.difficulty), context),
                  ),
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(.28)),
                      ),
                      child: const Text(
                        'POPULAR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Mark done'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withOpacity(.35)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    try {
                      await _workoutLogRepository.logWorkout(workout);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Logged "${workout.title}"')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.toString())));
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

  /* ---------- Small UI bits ---------- */

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

  Widget _statChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _difficultyLabel(String raw) =>
      WorkoutDifficulty.fromWire(raw).name; // if enum mapping exists

  Color _difficultyColor(String label, BuildContext context) {
    switch (label.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.redAccent;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Widget _pillChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _darken(color, .2),
        ),
      ),
    );
  }

  Widget _tinyChip(IconData icon, String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            t,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _darken(Color c, [double amount = .18]) {
    final f = 1 - amount;
    return Color.fromARGB(
      c.alpha,
      (c.red * f).round(),
      (c.green * f).round(),
      (c.blue * f).round(),
    );
  }

  Widget _buildSearchBar() {
    final primary = Theme.of(context).colorScheme.primary;
    return Hero(
      tag: 'workoutSearchBar',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkoutSearchPage(repo: _workoutRepository),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(.92),
              border: Border.all(color: Colors.black.withOpacity(.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: primary.withOpacity(.85)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search workouts, categories...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: .2,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Search',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: .5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------- Reusable Section Card (matches Nutrition look) ---------- */
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.label,
    required this.imagePath,
    required this.onTap,
  });

  final String label;
  final String imagePath;
  final VoidCallback onTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  double _scale = 1;

  Color _accent(String name) {
    final n = name.toLowerCase();
    if (n.contains('strength')) return Colors.redAccent;
    if (n.contains('cardio')) return Colors.orange;
    if (n.contains('yoga') || n.contains('flex')) return Colors.teal;
    if (n.contains('hit') || n.contains('hiit')) return Colors.purple;
    if (n.contains('custom')) return Colors.indigo;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(widget.label);
    return Listener(
      onPointerDown: (_) => setState(() => _scale = .965),
      onPointerUp:   (_) => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.imagePath,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                  // Vignette + slight tint toward accent
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(.55),
                          Colors.black.withOpacity(.25),
                          Colors.black.withOpacity(.55),
                        ],
                      ),
                    ),
                  ),
                  // Centered text only
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: .6,
                          height: 1.15,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(.55),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Accent border
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: accent.withOpacity(.45),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WideCategoryCard extends StatelessWidget {
  const _WideCategoryCard({
    required this.label,
    required this.imagePath,
    required this.onTap,
  });

  final String label;
  final String imagePath;
  final VoidCallback onTap;

  Color _accent(String name) {
    final n = name.toLowerCase();
    if (n.contains('strength')) return Colors.redAccent;
    if (n.contains('cardio')) return Colors.orange;
    if (n.contains('yoga') || n.contains('flex')) return Colors.teal;
    if (n.contains('hit') || n.contains('hiit')) return Colors.purple;
    if (n.contains('custom')) return Colors.indigo;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(label);
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        height: 130, // Taller than grid version
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(.20),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
              // Wide soft gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(.60),
                      Colors.black.withOpacity(.25),
                      Colors.black.withOpacity(.60),
                    ],
                  ),
                ),
              ),
              // Centered larger text
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24, // Bigger
                        letterSpacing: .8,
                        height: 1.1,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(.55),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Accent outline
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: accent.withOpacity(.45),
                      width: 1.3,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------- Workout Hero Slider ---------- */
class _WorkoutHeroSlider extends StatefulWidget {
  const _WorkoutHeroSlider();
  @override
  State<_WorkoutHeroSlider> createState() => _WorkoutHeroSliderState();
}

class _WorkoutHeroSliderState extends State<_WorkoutHeroSlider> {
  final _controller = PageController();
  int _index = 0;
  Timer? _timer;

  static const _autoPlayInterval = Duration(seconds: 4);
  static const _animDuration = Duration(milliseconds: 650);

  final _slides = const [
    ('assets/images/workout.jpg', 'Train with intent.'),
    ('assets/images/workout2.jpg', 'Small reps. Big progress.'),
    ('assets/images/workout3.jpg', 'Stronger every session.'),
  ];

  @override
  void initState() {
    super.initState();
    // Start after first frame to avoid jank during initial layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleNextTick());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache all images to eliminate white flash while decoding.
    for (final (path, _) in _slides) {
      precacheImage(AssetImage(path), context);
    }
  }

  void _scheduleNextTick() {
    _timer?.cancel();
    _timer = Timer(_autoPlayInterval, _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    final next = (_index + 1) % _slides.length;
    _controller
        .animateToPage(
          next,
          duration: _animDuration,
          curve: Curves.easeInOutCubic,
        )
        .whenComplete(() {
      if (mounted) _scheduleNextTick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(26);
    return SizedBox(
      height: 190,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Black base to avoid white flashes
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
            PageView.builder(
              controller: _controller,
              allowImplicitScrolling: true, // prebuild neighbors
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: _slides.length,
              itemBuilder: (_, i) {
                final (path, quote) = _slides[i];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // gaplessPlayback keeps previous frame while next decodes
                    Image.asset(
                      path,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.high,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(.55),
                            Colors.black.withOpacity(.25),
                            Colors.black.withOpacity(.55),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, .15),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            quote,
                            key: ValueKey(quote),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'cursive',
                              color: Colors.white,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(.55),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: active ? 26 : 10,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withOpacity(.45),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
