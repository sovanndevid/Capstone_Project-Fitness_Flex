import 'package:flutter/material.dart';
import 'package:fitness_flex_app/widgets/workout_card.dart';

class WorkoutHomeScreen extends StatefulWidget {
  const WorkoutHomeScreen({super.key});

  @override
  State<WorkoutHomeScreen> createState() => _WorkoutHomeScreenState();
}

class _WorkoutHomeScreenState extends State<WorkoutHomeScreen> {
  // This list tracks the liked state for each workout
  final List<bool> _isLikedList = [false, false];

  // This function toggles the like state for a specific workout
  void _toggleLike(int index) {
    print('_toggleLike called for workout $index'); // ADD THIS LINE
    setState(() {
      _isLikedList[index] = !_isLikedList[index];
      print('Workout $index liked: ${_isLikedList[index]}'); // ADD THIS LINE TOO
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts Home'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Workout Cards - MAKE SURE YOU PASS THE CORRECT PARAMETERS!
            WorkoutCard(
              title: "Full Body Strength",
              category: "Strength Training",
              description: "Complete full body workout targeting all major muscle groups with compound exercises",
              duration: "45 min",
              calories: "320",
              difficulty: "Intermediate",
              isLiked: _isLikedList[0], // Pass the current state
              onLike: () => _toggleLike(0), // Pass the function to call
              onTap: () {},
            ),
            WorkoutCard(
              title: "Morning Yoga Flow",
              category: "Yoga & Flexibility",
              description: "Gentle yoga routine to start your day with stretching and breathing",
              duration: "30 min",
              calories: "180",
              difficulty: "Beginner",
              isLiked: _isLikedList[1], // Pass the current state
              onLike: () => _toggleLike(1), // Pass the function to call
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
