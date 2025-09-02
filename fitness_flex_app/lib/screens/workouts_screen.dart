import 'package:flutter/material.dart';
import 'package:fitness_flex_app/widgets/workout_card.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final List<bool> _isLikedList = [false, false];

  void _toggleLike(int index) {
    setState(() {
      _isLikedList[index] = !_isLikedList[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        centerTitle: false,
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories Section
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('Strength'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Cardio'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Yoga & Flexibility'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Popular Workouts Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Popular Workouts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            WorkoutCard(
              title: "Full Body Strength",
              category: "Strength Training",
              description:
                  "Complete full body workout targeting all major muscle groups with compound exercises",
              duration: "45 min",
              calories: "320",
              difficulty: "Intermediate",
              isLiked: _isLikedList[0],
              onLike: () => _toggleLike(0),
              onTap: () {},
            ),
            WorkoutCard(
              title: "Morning Yoga Flow",
              category: "Yoga & Flexibility",
              description:
                  "Gentle yoga routine to start your day with stretching and breathing",
              duration: "30 min",
              calories: "180",
              difficulty: "Beginner",
              isLiked: _isLikedList[1],
              onLike: () => _toggleLike(1),
              onTap: () {},
            ),
            const SizedBox(height: 16),

            // All Workouts Button
            Center(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('All Workouts'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    return Chip(label: Text(label), backgroundColor: Colors.grey[200]);
  }
}
