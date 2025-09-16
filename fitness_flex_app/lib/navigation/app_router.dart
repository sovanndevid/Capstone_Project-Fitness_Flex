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
      splash: (_) => const SplashPage(),
      onboarding: (_) => const OnboardingPage(),
      login: (_) => const LoginPage(),
      register: (_) => const RegisterPage(),
      home: (_) => const HomePage(),
      workout: (_) => const WorkoutListPage(),
      nutrition: (_) => const NutritionPage(),
      '/mealHistory': (_) => MealHistoryPage(nutritionRepository: _nutritionRepository),

      // NEW (form checker flow)
      formCheckMenu: (_) => const FormCheckMenuPage(),
      formCheck: (_) => const FormCheckerScreen(),
      formCheckSummary: (_) => const FormCheckSummaryPage(),
    };
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ... your other routes
      case workouts:
        return MaterialPageRoute(builder: (_) => const WorkoutHomeScreen());
      // ... your other routes
      default:
        return MaterialPageRoute(builder: (_) => const SplashPage());
    }
  }
}