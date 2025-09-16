import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/repositories/nutrition_repository.dart';
import 'package:fitness_flex_app/presentation/pages/meal_log_page.dart';
import 'package:fitness_flex_app/presentation/pages/water_tracker_page.dart';
import 'package:fitness_flex_app/presentation/pages/nutrition_goals_page.dart';
import 'package:fitness_flex_app/presentation/pages/meal_history_page.dart'; // <-- Add this import
import 'package:fitness_flex_app/data/models/meal.dart';
import 'package:fitness_flex_app/data/models/nutrition_goal.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final NutritionRepository _nutritionRepository = NutritionRepository();
  late Future<Map<String, double>> _nutritionSummaryFuture;
  late Future<double> _waterSummaryFuture;
  late Future<NutritionGoal> _nutritionGoalFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _nutritionSummaryFuture = _nutritionRepository.getTodayNutritionSummary();
    _waterSummaryFuture = _nutritionRepository.getTodayWaterSummary();
    _nutritionGoalFuture = _nutritionRepository.getNutritionGoal();
  }

  void _refreshData() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NutritionGoalsPage(
                    nutritionRepository: _nutritionRepository,
                    onGoalUpdated: _refreshData,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
          return Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildNutritionSummaryCard(),
              const SizedBox(height: 20),
              _buildWaterTrackingCard(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today\'s Meals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MealHistoryPage(
                            nutritionRepository: _nutritionRepository,
                          ),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildRecentMealsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionSummaryCard() {
    return FutureBuilder<Map<String, double>>(
      future: _nutritionSummaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard('Failed to load nutrition data');
        }

        final nutritionData = snapshot.data!;
        final calories = nutritionData['calories'] ?? 0;
        final protein = nutritionData['protein'] ?? 0;
        final carbs = nutritionData['carbs'] ?? 0;
        final fat = nutritionData['fat'] ?? 0;

        return FutureBuilder<NutritionGoal>(
          future: _nutritionGoalFuture,
          builder: (context, goalSnapshot) {
            final goal =
                goalSnapshot.data ??
                NutritionGoal(
                  dailyCalories: 2000,
                  dailyProtein: 150,
                  dailyCarbs: 250,
                  dailyFat: 70,
                  dailyWater: 2.5,
                );

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Today\'s Nutrition',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNutritionProgress(
                      'Calories',
                      calories,
                      goal.dailyCalories,
                      'kcal',
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMacroNutrient(
                            'Protein',
                            protein,
                            goal.dailyProtein,
                            'g',
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildMacroNutrient(
                            'Carbs',
                            carbs,
                            goal.dailyCarbs,
                            'g',
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildMacroNutrient(
                            'Fat',
                            fat,
                            goal.dailyFat,
                            'g',
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNutritionProgress(
    String label,
    double current,
    double goal,
    String unit,
    Color color,
  ) {
    final percentage = goal > 0 ? (current / goal) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${current.toStringAsFixed(0)}/$goal$unit',
              style: TextStyle(
                color: percentage > 1 ? Colors.red : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (percentage > 1 ? 1 : percentage).toDouble(),
          backgroundColor:
              Colors.grey[200] ?? Colors.grey, // FIXED: never nullable
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage > 1
                ? Colors.red
                : (color ?? Colors.orange), // FIXED: never nullable
          ),
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }

  Widget _buildMacroNutrient(
    String label,
    double current,
    double goal,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '${current.toStringAsFixed(0)}$unit',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'of ${goal.toStringAsFixed(0)}$unit',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildWaterTrackingCard() {
    return FutureBuilder<double>(
      future: _waterSummaryFuture,
      builder: (context, snapshot) {
        final waterAmount = snapshot.data ?? 0;

        return FutureBuilder<NutritionGoal>(
          future: _nutritionGoalFuture,
          builder: (context, goalSnapshot) {
            final goal = goalSnapshot.data?.dailyWater ?? 2.5;
            final percentage = goal > 0 ? (waterAmount / goal) : 0;

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Water Intake',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(Icons.water_drop, color: Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${waterAmount.toStringAsFixed(1)}L',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          '/ ${goal}L',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CircularPercentIndicator(
                      percent: percentage.toDouble(),
                      radius: 60.0,
                      lineWidth: 5.0,
                      backgroundColor: Colors.grey[200] ?? Colors.grey,
                      progressColor: Colors.blue,
                      center: Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WaterTrackerPage(
                                nutritionRepository: _nutritionRepository,
                                onWaterAdded: _refreshData,
                              ),
                            ),
                          );
                        },
                        child: const Text('Track Water'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          icon: Icons.breakfast_dining,
          label: 'Breakfast',
          onTap: () => _navigateToMealLog('breakfast'),
        ),
        _buildActionButton(
          icon: Icons.lunch_dining,
          label: 'Lunch',
          onTap: () => _navigateToMealLog('lunch'),
        ),
        _buildActionButton(
          icon: Icons.dinner_dining,
          label: 'Dinner',
          onTap: () => _navigateToMealLog('dinner'),
        ),
        _buildActionButton(
          icon: Icons.cake,
          label: 'Snack',
          onTap: () => _navigateToMealLog('snack'),
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
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.2),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRecentMealsList() {
    return FutureBuilder<List<Meal>>(
      future: _nutritionRepository.getTodayMeals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final meals = snapshot.data ?? [];

        return Column(
          children: [
            // Meals list or empty state
            if (meals.isEmpty)
              Column(
                children: [
                  const Icon(Icons.restaurant, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No meals logged today',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _navigateToMealLog('breakfast'),
                    child: const Text('Log Your First Meal'),
                  ),
                  const SizedBox(height: 16),
                ],
              )
            else
              Column(
                children: meals.map((meal) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getMealTypeColor(meal.mealType),
                        child: Icon(
                          _getMealTypeIcon(meal.mealType),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(meal.name),
                      subtitle: Text(
                        '${meal.calories.toStringAsFixed(0)} kcal • ${meal.mealType}',
                      ),
                      trailing: Text(
                        '${meal.protein.toStringAsFixed(0)}P ${meal.carbs.toStringAsFixed(0)}C ${meal.fat.toStringAsFixed(0)}F',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.blue;
      case 'snack':
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cake;
      default:
        return Icons.restaurant;
    }
  }

  Widget _buildLoadingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  void _navigateToMealLog(String mealType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealLogPage(
          nutritionRepository: _nutritionRepository,
          mealType: mealType,
          onMealAdded: _refreshData,
        ),
      ),
    );
  }
}

// test to mains

