import 'package:flutter/material.dart';

// Core pages
import 'package:fitness_flex_app/presentation/pages/splash_page.dart';
import 'package:fitness_flex_app/presentation/pages/onboarding_page.dart';
import 'package:fitness_flex_app/presentation/pages/login_page.dart';
import 'package:fitness_flex_app/presentation/pages/register_page.dart';
import 'package:fitness_flex_app/presentation/pages/home_page.dart';
import 'package:fitness_flex_app/presentation/pages/workout_list_page.dart';
import 'package:fitness_flex_app/presentation/pages/nutrition_page.dart';
import 'package:fitness_flex_app/presentation/pages/meal_history_page.dart';
import 'package:fitness_flex_app/presentation/pages/verify_email_page.dart';
import 'package:fitness_flex_app/presentation/pages/progress_page.dart'; // <-- add

// Data
import 'package:fitness_flex_app/data/repositories/nutrition_repository.dart';

// Features: form check
import 'package:fitness_flex_app/features/form_check/form_check_menu_page.dart';
import 'package:fitness_flex_app/features/form_check/form_checker_screen.dart';
import 'package:fitness_flex_app/features/form_check/form_check_summary_page.dart';

// Screens (optional workout pages)

class AppRouter {
  // 🔹 Auth & onboarding
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verifyEmail';

  // 🔹 Main sections
  static const String nutritionGoals = '/nutritionGoals';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String workout = '/workout';
  static const String nutrition = '/nutrition';
  static const String progress = '/progress';
  static const String community = '/community';
  static const String settings = '/settings';

  // 🔹 Form check
  static const String formCheckMenu = '/form-check-menu';
  static const String formCheck = '/form-check';
  static const String formCheckSummary = '/form-check-summary';

  static final NutritionRepository _nutritionRepository = NutritionRepository();

  /// All routes in the app
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // Auth
      splash: (_) => const SplashPage(),
      onboarding: (_) => const OnboardingPage(),
      login: (_) => const LoginPage(),
      register: (_) => const RegisterPage(),
      verifyEmail: (_) => const VerifyEmailPage(),

      // Main
      home: (_) => const HomePage(),
      workout: (_) => const WorkoutListPage(),
      nutrition: (_) => const NutritionPage(),
      progress: (_) => const ProgressPage(), // <-- add
      '/mealHistory': (_) =>
          MealHistoryPage(nutritionRepository: _nutritionRepository),

      // Form check
      formCheckMenu: (_) => const FormCheckMenuPage(),
      formCheck: (_) => const FormCheckerScreen(),
      formCheckSummary: (_) => const FormCheckSummaryPage(),
    };
  }

  /// Fallback / dynamic routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case workout:
        // You can change to WorkoutHome or WorkoutsScreen
        return MaterialPageRoute(builder: (_) => const WorkoutListPage());
      case progress:
        return MaterialPageRoute(builder: (_) => const ProgressPage());
      default:
        return MaterialPageRoute(builder: (_) => const SplashPage());
    }
  }
}
