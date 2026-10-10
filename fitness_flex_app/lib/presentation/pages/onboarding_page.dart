import 'package:flutter/material.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';
import 'package:fitness_flex_app/core/themes/app_theme.dart';

/// Onboarding presentation only; all route choices and copy remain intact.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<Map<String, String>> onboardingData = [
    {'title': 'Track Your Workouts', 'description': 'Log your exercises, sets, reps, and weights with ease', 'image': '💪'},
    {'title': 'Personalized Plans', 'description': 'Get customized workout plans based on your goals', 'image': '📊'},
    {'title': 'Monitor Progress', 'description': 'See your improvements with detailed charts and analytics', 'image': '📈'},
  ];
  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  void _continue() {
    if (_currentPage < onboardingData.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 740;
    final ink = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: EdgeInsets.fromLTRB(wide ? 52 : 20, 18, wide ? 52 : 20, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(width: 42, height: 42, alignment: Alignment.center,
                decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(12)),
                child: const Text('FF', style: TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.w900, fontSize: 15))),
              const SizedBox(width: 12),
              Text('FitnessFlex', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -.7)),
              const Spacer(),
              Text('MOVE BETTER  /  FEEL STRONGER',
                style: TextStyle(color: muted, fontSize: wide ? 11 : 8, fontFamily: 'monospace', letterSpacing: .2)),
            ]),
            const SizedBox(height: 12),
            Expanded(child: PageView.builder(
              controller: _pageController,
              itemCount: onboardingData.length,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) {
                final info = onboardingData[index];
                final icon = [Icons.fitness_center, Icons.auto_graph, Icons.timeline][index];
                final illustration = Container(
                  height: wide ? 330 : 205,
                  constraints: const BoxConstraints(maxWidth: 450),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface, borderRadius: BorderRadius.circular(27)),
                  child: Stack(children: [
                    Positioned(top: -120, right: -55,
                      child: Container(width: 300, height: 300,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.secondaryColor.withOpacity(.22), width: 2)))),
                    Positioned(bottom: -140, left: -30,
                      child: Container(width: 260, height: 260,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.secondaryColor.withOpacity(.12), width: 2)))),
                    Positioned(top: 23, left: 24, child: Text('FITNESSFLEX / 0' + (index+1).toString(),
                      style: const TextStyle(color: Color(0xFFB6C9C1), fontSize: 10, fontFamily: 'monospace'))),
                    Center(child: Container(width: 115, height: 115,
                      decoration: BoxDecoration(color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(27)),
                      child: Icon(icon, size: 61, color: AppTheme.primaryColor))),
                    const Positioned(right: 23, bottom: 23, child: Text('YOUR PROGRESS. IN MOTION. ↗',
                      style: TextStyle(color: AppTheme.secondaryColor, fontSize: 9.5, fontFamily: 'monospace'))),
                  ]),
                );
                final caption = ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('YOUR FITNESS, CONNECTED  /  0' + (index+1).toString(),
                        style: TextStyle(color: muted, fontSize: 11, fontFamily: 'monospace', letterSpacing: 1)),
                      const SizedBox(height: 13),
                      Text(info['title']!, textAlign: wide ? TextAlign.left : TextAlign.center,
                        style: TextStyle(fontSize: wide ? 43 : 29, height: 1.13, color: ink,
                          fontWeight: FontWeight.w900, letterSpacing: -1.35)),
                      const SizedBox(height: 14),
                      Text(info['description']!, textAlign: wide ? TextAlign.left : TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 15, height: 1.65)),
                    ],
                  ),
                );
                return Center(child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: wide
                    ? Row(children: [
                        Expanded(child: illustration), const SizedBox(width: 52),
                        Expanded(child: caption),
                      ])
                    : Column(mainAxisSize: MainAxisSize.min, children: [
                        illustration, const SizedBox(height: 27), caption,
                      ]),
                ));
              },
            )),
            const SizedBox(height: 8),
            Row(children: [
              for (var i = 0; i < onboardingData.length; i++)
                AnimatedContainer(duration: const Duration(milliseconds: 250),
                  width: _currentPage == i ? 34 : 10, height: 7,
                  margin: const EdgeInsets.only(right: 7),
                  decoration: BoxDecoration(
                    color: _currentPage == i ? AppTheme.secondaryColor : AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(10))),
              const Spacer(),
              if (_currentPage < onboardingData.length - 1)
                TextButton(onPressed: () => Navigator.pushReplacementNamed(context, AppRouter.login), child: const Text('Skip')),
              const SizedBox(width: 8),
              ElevatedButton.icon(onPressed: _continue,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(_currentPage < onboardingData.length - 1 ? 'Next' : 'Get Started')),
            ]),
          ]),
        ),
      ))),
    );
  }
}
