import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fitness_flex_app/core/themes/app_theme.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Sample user data
  final Map<String, dynamic> userData = {
    'name': 'Alex',
    'goal': 'Lose Weight',
    'daysCompleted': 16,
    'targetDays': 30,
    'caloriesBurned': 420,
    'caloriesTarget': 600,
    'waterIntake': 1.8,
    'waterTarget': 2.5,
    'steps': 7843,
    'stepsTarget': 10000,
  };

  // Sample workout data
  final List<Map<String, dynamic>> recentWorkouts = [
    {
      'name': 'Chest & Triceps',
      'duration': '45 min',
      'calories': 320,
      'date': 'Today',
      'icon': Icons.fitness_center,
    },
    {
      'name': 'Morning Yoga',
      'duration': '30 min',
      'calories': 180,
      'date': 'Yesterday',
      'icon': Icons.self_improvement,
    },
    {
      'name': 'Evening Run',
      'duration': '35 min',
      'calories': 280,
      'date': '2 days ago',
      'icon': Icons.directions_run,
    },
  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      // Workout tab
      Navigator.pushNamed(context, AppRouter.workout);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${userData['name']}!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              userData['goal'],
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Card
            _buildProgressCard(),
            const SizedBox(height: 20),

            // Today's Stats
            const Text(
              "Today's Stats",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Stats Grid
            _buildStatsGrid(),
            const SizedBox(height: 24),

            // Recent Workouts
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

            // Workout List
            _buildWorkoutList(),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildQuickActions(),
          ],
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

  Widget _buildProgressCard() {
    double progress = userData['daysCompleted'] / userData['targetDays'];

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
              percent: progress,
              center: Text(
                "${(progress * 100).toStringAsFixed(0)}%",
                style: const TextStyle(color: Colors.white),
              ),
              barRadius: const Radius.circular(10),
              progressColor: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              "Day ${userData['daysCompleted']} of ${userData['targetDays']}",
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

  Widget _buildStatsGrid() {
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
          value: '${userData['caloriesBurned']}',
          subtitle: '/ ${userData['caloriesTarget']} kcal',
          icon: Icons.local_fire_department,
          color: Colors.orange,
          progress: userData['caloriesBurned'] / userData['caloriesTarget'],
        ),
        _buildStatCard(
          title: 'Water',
          value: '${userData['waterIntake']}L',
          subtitle: '/ ${userData['waterTarget']}L',
          icon: Icons.water_drop,
          color: Colors.blue,
          progress: userData['waterIntake'] / userData['waterTarget'],
        ),
        _buildStatCard(
          title: 'Steps',
          value: '${userData['steps']}',
          subtitle: '/ ${userData['stepsTarget']}',
          icon: Icons.directions_walk,
          color: Colors.green,
          progress: userData['steps'] / userData['stepsTarget'],
        ),
        _buildStatCard(
          title: 'Sleep',
          value: '7h 30m',
          subtitle: '/ 8h goal',
          icon: Icons.nightlight_round,
          color: Colors.purple,
          progress: 7.5 / 8,
        ),
      ],
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
              valueColor: AlwaysStoppedAnimation<Color>(color),
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutList() {
    return Column(
      children: recentWorkouts.map((workout) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: Icon(workout['icon'], color: AppTheme.primaryColor),
            ),
            title: Text(
              workout['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${workout['duration']} • ${workout['calories']} kcal",
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  workout['date'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Completed",
                    style: TextStyle(fontSize: 10, color: Colors.green),
                  ),
                ),
              ],
            ),
            onTap: () {},
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          icon: Icons.add,
          label: 'Start Workout',
          onTap: () {},
        ),
        _buildActionButton(
          icon: Icons.restaurant,
          label: 'Log Meal',
          onTap: () {},
        ),
        _buildActionButton(
          icon: Icons.water_drop,
          label: 'Log Water',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primaryColor,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
