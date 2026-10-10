import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_flex_app/presentation/pages/onboarding_page.dart';
import 'package:fitness_flex_app/features/form_check/form_check_menu_page.dart';

void main() {
  testWidgets('Onboarding advances through actual app slides', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
    expect(find.text('Track Your Workouts'), findsOneWidget);
    expect(find.text('Log your exercises, sets, reps, and weights with ease'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Personalized Plans'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Monitor Progress'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Squat is selectable but unimplemented exercises stay disabled', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FormCheckMenuPage()));
    expect(find.text('Back Squat'), findsOneWidget);
    expect(find.text('Push-up'), findsOneWidget);
    final squat = tester.widget<ListTile>(find.ancestor(
      of: find.text('Back Squat'), matching: find.byType(ListTile)));
    final pushup = tester.widget<ListTile>(find.ancestor(
      of: find.text('Push-up'), matching: find.byType(ListTile)));
    expect(squat.onTap, isNotNull);
    expect(pushup.onTap, isNull);
  });
}
