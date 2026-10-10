import 'package:flutter/material.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';
import 'package:fitness_flex_app/core/themes/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}
class _SplashPageState extends State<SplashPage> {
  @override
  void initState() { super.initState(); _navigateToHome(); }
  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRouter.onboarding);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppTheme.darkSurface,
      body: SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(height: 88, width: 88,
            decoration: BoxDecoration(color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(25)),
            alignment: Alignment.center,
            child: const Text('FF', style: TextStyle(color: AppTheme.primaryColor,
              fontWeight: FontWeight.w900, fontSize: 34, letterSpacing: -3))),
          const SizedBox(height: 26),
          const Text('FitnessFlex', style: TextStyle(color: Colors.white,
            fontSize: 39, fontWeight: FontWeight.w900, letterSpacing: -2)),
          const SizedBox(height: 9),
          const Text('MOVE BETTER. KNOW MORE.',
            style: TextStyle(color: AppTheme.secondaryColor,
              fontFamily: 'monospace', fontSize: 11, letterSpacing: 2)),
          const SizedBox(height: 38),
          const SizedBox(height: 28, width: 28,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.secondaryColor)),
        ]),
      ))),
    );
  }
}
