import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/models/water_intake.dart';
import 'package:fitness_flex_app/data/models/nutrition_goal.dart';
import 'package:fitness_flex_app/data/repositories/nutrition_repository.dart';

class WaterTrackerPage extends StatefulWidget {
  final NutritionRepository nutritionRepository;
  final VoidCallback onWaterAdded;

  const WaterTrackerPage({
    super.key,
    required this.nutritionRepository,
    required this.onWaterAdded,
  });

  @override
  State<WaterTrackerPage> createState() => _WaterTrackerPageState();
}

class _WaterTrackerPageState extends State<WaterTrackerPage> {
  final List<double> _waterAmounts = [0.25, 0.5, 1.0];
  double _selectedAmount = 0.25;
  List<WaterIntake> _todayIntakes = [];

  @override
  void initState() {
    super.initState();
    _loadTodayIntakes();
  }

  void _loadTodayIntakes() async {
    final intakes = await widget.nutritionRepository.getTodayWaterIntakes();
    setState(() {
      _todayIntakes = intakes;
    });
  }

  void _addWaterIntake() async {
    final intake = WaterIntake(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      amount: _selectedAmount,
      time: TimeOfDay.now().format(context),
    );

    await widget.nutritionRepository.addWaterIntake(intake);
    setState(() {
      _todayIntakes.add(intake);
    });
    widget.onWaterAdded();
  }

  void _deleteWaterIntake(WaterIntake intake) async {
    await widget.nutritionRepository.deleteWaterIntake(intake.id);
    setState(() {
      _todayIntakes.removeWhere((water) => water.id == intake.id);
    });

    widget.onWaterAdded();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Water intake deleted')));
  }

  double _getTotalWater() {
    return _todayIntakes.fold(0, (sum, intake) => sum + intake.amount);
  }

  @override
  Widget build(BuildContext context) {
    final totalWater = _getTotalWater();

    return Scaffold(
      appBar: AppBar(title: const Text('Water Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Water Progress
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Today\'s Water Intake',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${totalWater.toStringAsFixed(2)}L',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<NutritionGoal>(
                      future: widget.nutritionRepository.getNutritionGoal(),
                      builder: (context, snapshot) {
                        final goal = snapshot.data?.dailyWater ?? 2.5;
                        final percentage = goal > 0 ? (totalWater / goal) : 0;

                        return Column(
                          children: [
                            LinearProgressIndicator(
                              value: (percentage > 1 ? 1 : percentage)
                                  .toDouble(), // <-- FIX HERE
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Goal: ${goal}L',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Water Amount Selector
            const Text(
              'Select Amount:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _waterAmounts.map((amount) {
                return ChoiceChip(
                  label: Text('${amount}L'),
                  selected: _selectedAmount == amount,
                  onSelected: (selected) {
                    setState(() {
                      _selectedAmount = amount;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Add Water Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addWaterIntake,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  'Add Water',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Today's Intakes
            const Text(
              'Today\'s Intakes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _todayIntakes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.water_drop, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No water logged today'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _todayIntakes.length,
                      itemBuilder: (context, index) {
                        final intake = _todayIntakes[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.water_drop,
                            color: Colors.blue,
                          ),
                          title: Text('${intake.amount}L'),
                          subtitle: Text(intake.time),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteWaterIntake(intake),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
