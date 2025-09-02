import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/models/nutrition_goal.dart';
import 'package:fitness_flex_app/data/repositories/nutrition_repository.dart';

class NutritionGoalsPage extends StatefulWidget {
  final NutritionRepository nutritionRepository;
  final VoidCallback onGoalUpdated;

  const NutritionGoalsPage({
    super.key,
    required this.nutritionRepository,
    required this.onGoalUpdated,
  });

  @override
  State<NutritionGoalsPage> createState() => _NutritionGoalsPageState();
}

class _NutritionGoalsPageState extends State<NutritionGoalsPage> {
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentGoals();
  }

  void _loadCurrentGoals() async {
    final goal = await widget.nutritionRepository.getNutritionGoal();
    setState(() {
      _caloriesController.text = goal.dailyCalories.toStringAsFixed(0);
      _proteinController.text = goal.dailyProtein.toStringAsFixed(0);
      _carbsController.text = goal.dailyCarbs.toStringAsFixed(0);
      _fatController.text = goal.dailyFat.toStringAsFixed(0);
      _waterController.text = goal.dailyWater.toStringAsFixed(1);
    });
  }

  void _saveGoals() async {
    final goal = NutritionGoal(
      dailyCalories: double.tryParse(_caloriesController.text) ?? 2000,
      dailyProtein: double.tryParse(_proteinController.text) ?? 150,
      dailyCarbs: double.tryParse(_carbsController.text) ?? 250,
      dailyFat: double.tryParse(_fatController.text) ?? 70,
      dailyWater: double.tryParse(_waterController.text) ?? 2.5,
    );

    await widget.nutritionRepository.updateNutritionGoal(goal);
    widget.onGoalUpdated();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Goals updated successfully')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Goals'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveGoals),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Calories Goal
            _buildGoalCard(
              title: 'Daily Calories',
              icon: Icons.local_fire_department,
              color: Colors.orange,
              controller: _caloriesController,
              unit: 'kcal',
            ),
            const SizedBox(height: 16),

            // Macronutrients Goals
            const Text(
              'Macronutrients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMacroGoalCard(
                    title: 'Protein',
                    icon: Icons.fitness_center,
                    color: Colors.blue,
                    controller: _proteinController,
                    unit: 'g',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMacroGoalCard(
                    title: 'Carbs',
                    icon: Icons.energy_savings_leaf,
                    color: Colors.green,
                    controller: _carbsController,
                    unit: 'g',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildMacroGoalCard(
              title: 'Fat',
              icon: Icons.oil_barrel,
              color: Colors.red,
              controller: _fatController,
              unit: 'g',
            ),
            const SizedBox(height: 20),

            // Water Goal
            _buildGoalCard(
              title: 'Daily Water',
              icon: Icons.water_drop,
              color: Colors.blue,
              controller: _waterController,
              unit: 'L',
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveGoals,
                child: const Text('Save Goals'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required String unit,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Goal ($unit)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroGoalCard({
    required String title,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required String unit,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Goal ($unit)',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
