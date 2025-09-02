import 'package:flutter/material.dart';
import 'package:fitness_flex_app/presentation/pages/splash_page.dart';
import 'package:fitness_flex_app/presentation/pages/onboarding_page.dart';
import 'package:fitness_flex_app/presentation/pages/login_page.dart';
import 'package:fitness_flex_app/presentation/pages/register_page.dart';
import 'package:fitness_flex_app/presentation/pages/home_page.dart';
import 'package:fitness_flex_app/presentation/pages/workout_list_page.dart';
import 'package:fitness_flex_app/presentation/pages/nutrition_page.dart';
import 'package:fitness_flex_app/presentation/pages/meal_history_page.dart';
import 'package:fitness_flex_app/data/repositories/nutrition_repository.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String workout = '/workout';
  static const String nutrition = '/nutrition';
  static const String progress = '/progress';
  static const String community = '/community';
  static const String settings = '/settings';
  static const formCheck = '/form-check';

  static final NutritionRepository _nutritionRepository = NutritionRepository();

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashPage(),
      onboarding: (context) => const OnboardingPage(),
      login: (context) => const LoginPage(),
      register: (context) => const RegisterPage(),
      home: (context) => const HomePage(),
      workout: (context) => const WorkoutListPage(),
      nutrition: (context) => const NutritionPage(),
      '/mealHistory': (context) =>
          MealHistoryPage(nutritionRepository: _nutritionRepository),
      // Add other routes as you create the pages
    };
  }
}
