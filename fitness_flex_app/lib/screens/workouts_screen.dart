import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/models/workout_model.dart';
import 'package:fitness_flex_app/data/repositories/workout_repository.dart';
import 'package:fitness_flex_app/presentation/pages/workout_detail_page.dart';
import 'package:fitness_flex_app/presentation/pages/workout_category_page.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  // Single dynamic repo (optionally pass Firestore + userId to enable favorites)
  final WorkoutRepository _repo = WorkoutRepository();
  // final WorkoutRepository _repo = WorkoutRepository(
  //   firestore: FirebaseFirestore.instance,
  //   userId: FirebaseAuth.instance.currentUser?.uid,
  // );

  late Future<List<WorkoutCategory>> _categoriesFuture;
  late Future<List<Workout>> _popularFuture;
  late Future<List<Workout>> _allFuture;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    _categoriesFuture = _repo.getCategories();
    _popularFuture = _repo.getPopularWorkouts();
    _allFuture = _repo.getWorkouts();
  }

  Future<void> _refresh() async {
    setState(_loadAll);
    await Future.delayed(const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Categories
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Categories',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              FutureBuilder<List<WorkoutCategory>>(
                future: _categoriesFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError || !snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Failed to load categories'),
                    );
                  }
                  final cats = snap.data!;
                  return SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cats.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final c = cats[i];
                        return ActionChip(
                          label: Text(c.name),
                          avatar: Text(c.emoji),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkoutCategoryPage(
                                  workoutRepository: _repo,
                                  category: c, // pass enum (uses c.wire inside)
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // Popular Workouts
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Popular Workouts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Workout>>(
                future: _popularFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('No popular workouts found'),
                    );
                  }
                  final items = snap.data!;
                  return SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (_, i) => SizedBox(
                        width: 280,
                        child: _workoutCard(items[i], isPopular: true),
                      ),
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemCount: items.length,
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'All Workouts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // All Workouts
              FutureBuilder<List<Workout>>(
                future: _allFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('No workouts found'),
                    );
                  }
                  final items = snap.data!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: items
                          .map((w) => Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: _workoutCard(w, isPopular: false),
                              ))
                          .toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _workoutCard(Workout w, {required bool isPopular}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WorkoutDetailPage(workout: w)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(w.imageUrl, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          w.category,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      w.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: w.isFavorite ? Theme.of(context).colorScheme.primary : Colors.grey,
                    ),
                    onPressed: () async {
                      await _repo.toggleFavorite(w.id); // no-op if Firestore/uid not set
                      _refresh();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                w.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat(Icons.access_time, w.duration),
                  _stat(Icons.local_fire_department, '${w.calories} cal'),
                  _stat(Icons.bar_chart, w.difficulty),
                ],
              ),

              if (isPopular) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
