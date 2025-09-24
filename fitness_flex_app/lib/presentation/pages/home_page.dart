import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fitness_flex_app/core/themes/app_theme.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';
import 'chat_screen.dart';

// NEW: use the repo to get live totals from Firestore
import 'package:fitness_flex_app/data/repositories/nutrition_repository.dart';
import 'package:fitness_flex_app/data/models/nutrition_goal.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  Map<String, dynamic>? _userData;
  bool _loading = true;

  // ---- NEW: nutrition data for "Today's Stats"
  final NutritionRepository _nutritionRepository = NutritionRepository();
  late Future<Map<String, double>> _todaySummaryFuture;
  late Future<NutritionGoal> _goalFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNutritionFutures();
  }

  void _loadNutritionFutures() {
    _todaySummaryFuture = _nutritionRepository.getTodayNutritionSummary();
    _goalFuture = _nutritionRepository.getNutritionGoal();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _userData = doc.data();
            _loading = false;
          });
        } else {
          setState(() {
            _userData = {};
            _loading = false;
          });
        }
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load user data: $e")),
      );
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.pushNamed(context, AppRouter.workout);
    } else if (index == 2) {
      Navigator.pushNamed(context, AppRouter.nutrition)
          .then((_) => setState(_loadNutritionFutures)); // refresh after returning
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = _userData?['firstName'] ?? "User";
    final goal = _userData?['fitnessGoal'] ?? "Your Goal";

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $name!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              goal,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Chat with Fitness Assistant',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(_loadNutritionFutures),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressCard(),
              const SizedBox(height: 20),

              const Text(
                "Today's Stats",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // ---- NEW: dynamic stats grid
              _buildStatsGridDynamic(),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Workouts",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(onPressed: () {}, child: const Text("View All")),
                ],
              ),
              const SizedBox(height: 16),

              _buildWorkoutList(),
              const SizedBox(height: 24),

              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildQuickActions(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRouter.formCheck),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Form Checker'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Nutrition'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Progress'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildProgressCard() {
    final daysCompleted = _userData?['daysCompleted'] ?? 0;
    final targetDays = _userData?['targetDays'] ?? 30;
    double progress = targetDays > 0 ? daysCompleted / targetDays : 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            LinearPercentIndicator(
              animation: true,
              lineHeight: 20,
              animationDuration: 1000,
              percent: progress.clamp(0, 1),
              center: Text(
                "${(progress * 100).toStringAsFixed(0)}%",
                style: const TextStyle(color: Colors.white),
              ),
              barRadius: const Radius.circular(10),
              progressColor: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              "Day $daysCompleted of $targetDays",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Keep going! You're doing great!",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ===== NEW: Dynamic stats grid using Firestore data =====
  Widget _buildStatsGridDynamic() {
    return FutureBuilder(
      future: Future.wait([_todaySummaryFuture, _goalFuture]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text("Couldn't load today's stats",
              style: TextStyle(color: Colors.red));
        }

        final summary = snapshot.data![0] as Map<String, double>;
        final goal = snapshot.data![1] as NutritionGoal;

        final calories = summary['calories'] ?? 0;
        final protein  = summary['protein']  ?? 0;
        final carbs    = summary['carbs']    ?? 0;
        final fat      = summary['fat']      ?? 0;

        final calProg = goal.dailyCalories > 0 ? calories / goal.dailyCalories : 0;
        final proProg = goal.dailyProtein  > 0 ? protein  / goal.dailyProtein  : 0;
        final carbProg= goal.dailyCarbs    > 0 ? carbs    / goal.dailyCarbs    : 0;
        final fatProg = goal.dailyFat      > 0 ? fat      / goal.dailyFat      : 0;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              title: 'Calories',
              value: '${calories.toStringAsFixed(0)}',
              subtitle: 'of ${goal.dailyCalories.toStringAsFixed(0)} kcal',
              icon: Icons.local_fire_department,
              color: Colors.orange,
              progress: calProg.clamp(0, 1).toDouble(),
            ),
            _buildStatCard(
              title: 'Protein',
              value: '${protein.toStringAsFixed(0)} g',
              subtitle: 'of ${goal.dailyProtein.toStringAsFixed(0)} g',
              icon: Icons.fitness_center,
              color: Colors.red,
              progress: proProg.clamp(0, 1).toDouble(),
            ),
            _buildStatCard(
              title: 'Carbs',
              value: '${carbs.toStringAsFixed(0)} g',
              subtitle: 'of ${goal.dailyCarbs.toStringAsFixed(0)} g',
              icon: Icons.rice_bowl,
              color: Colors.green,
              progress: carbProg.clamp(0, 1).toDouble(),
            ),
            _buildStatCard(
              title: 'Fat',
              value: '${fat.toStringAsFixed(0)} g',
              subtitle: 'of ${goal.dailyFat.toStringAsFixed(0)} g',
              icon: Icons.water_drop,
              color: Colors.blue,
              progress: fatProg.clamp(0, 1).toDouble(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color),
                Text(title, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progress > 1 ? Colors.red : color),
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutList() {
    // Placeholder for now — later hook to Firestore
    final workouts = [
      {"name": "Chest & Triceps", "duration": "45 min", "calories": 320, "date": "Today", "icon": Icons.fitness_center},
      {"name": "Morning Yoga", "duration": "30 min", "calories": 180, "date": "Yesterday", "icon": Icons.self_improvement},
      {"name": "Evening Run", "duration": "35 min", "calories": 280, "date": "2 days ago", "icon": Icons.directions_run},
    ];

    return Column(
      children: workouts.map((workout) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: Icon(workout['icon'] as IconData, color: AppTheme.primaryColor),
            ),
            title: Text(
              workout['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("${workout['duration']} • ${workout['calories']} kcal"),
            trailing: Text(workout['date'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(icon: Icons.add, label: 'Start Workout', onTap: () {}),
        _buildActionButton(icon: Icons.restaurant, label: 'Log Meal', onTap: () {
          Navigator.pushNamed(context, AppRouter.nutrition)
              .then((_) => setState(_loadNutritionFutures)); // refresh on return
        }),
        _buildActionButton(icon: Icons.water_drop, label: 'Log Water', onTap: () {
          // keeps your water tracker behavior
          Navigator.pushNamed(context, AppRouter.nutrition)
              .then((_) => setState(_loadNutritionFutures));
        }),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primaryColor,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
