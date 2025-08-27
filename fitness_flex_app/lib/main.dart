import 'package:flutter/material.dart';
import 'package:fitness_flex_app/core/themes/app_theme.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';
import 'widgets/workout_card.dart';

void main() {
  runApp(const FitnessFlexApp());
}

class FitnessFlexApp extends StatelessWidget {
  const FitnessFlexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitnessFlex',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRouter.splash,
      routes: AppRouter.getRoutes(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Example usage of MyApp with WorkoutCard widgets
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Conquer Gym")),
        body: ListView(
          children: [
            WorkoutCard(
              title: "Push Day",
              description: "Chest, Shoulders, Triceps workout plan",
              onTap: () {
                print("Push Day tapped!");
              },
            ),
            WorkoutCard(
              title: "Pull Day",
              description: "Back and Biceps workout plan",
              onTap: () {
                print("Pull Day tapped!");
              },
            ),
          ],
        ),
      ),
    );
  }
}
