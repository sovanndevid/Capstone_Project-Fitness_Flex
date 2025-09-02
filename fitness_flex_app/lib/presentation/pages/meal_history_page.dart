import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/models/meal.dart';
import 'package:fitness_flex_app/data/repositories/nutrition_repository.dart';

class MealHistoryPage extends StatefulWidget {
  final NutritionRepository nutritionRepository;

  const MealHistoryPage({super.key, required this.nutritionRepository});

  @override
  State<MealHistoryPage> createState() => _MealHistoryPageState();
}

class _MealHistoryPageState extends State<MealHistoryPage> {
  late Future<List<Meal>> _allMealsFuture;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  void _loadMeals() {
    // For now, we'll just get today's meals
    // In a real app, you'd get meals for the selected date
    _allMealsFuture = widget.nutritionRepository.getTodayMeals();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadMeals();
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Meal>>(
        future: _allMealsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No meals found for this date'),
                ],
              ),
            );
          }

          final meals = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${meal.calories.toStringAsFixed(0)} kcal • ${meal.mealType}',
                      ),
                      Text('Serving: ${meal.servingSize}g'),
                      if (meal.description.isNotEmpty)
                        Text(
                          meal.description,
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: Text(
                    '${meal.protein.toStringAsFixed(0)}P ${meal.carbs.toStringAsFixed(0)}C ${meal.fat.toStringAsFixed(0)}F',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
