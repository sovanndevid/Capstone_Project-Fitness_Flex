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

// NEW (form checker flow)
import 'package:fitness_flex_app/features/form_check/form_checker_screen.dart';
import 'package:fitness_flex_app/features/form_check/form_check_menu_page.dart';
import 'package:fitness_flex_app/features/form_check/form_check_summary_page.dart';

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

  // Form checker flow
  static const String formCheckMenu = '/form-check-menu';
  static const String formCheck = '/form-check';
  static const String formCheckSummary = '/form-check-summary';

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
}