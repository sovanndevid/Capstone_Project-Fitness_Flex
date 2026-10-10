import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_flex_app/presentation/pages/guest_experience_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GuestExperiencePage()));
    await tester.pumpAndSettle();
  }

  testWidgets('Guest home loads without Firebase and shows local-only privacy notice',
      (tester) async {
    await launch(tester);
    expect(find.text('Train your way.'), findsOneWidget);
    expect(find.textContaining('Guest data stays on this device'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('Guest can browse exercises and record a local completion',
      (tester) async {
    await launch(tester);
    await tester.tap(find.text('Exercises'));
    await tester.pumpAndSettle();
    expect(find.text('Back squat'), findsOneWidget);
    await tester.tap(find.text('Back squat'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mark exercise completed'), findsOneWidget);
    await tester.tap(find.text('Mark exercise completed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Guest water tracker increases and progress shows saved value',
      (tester) async {
    await launch(tester);
    await tester.tap(find.text('Hydration'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a glass'));
    await tester.pumpAndSettle();
    expect(find.text('1 glasses'), findsOneWidget);
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Glasses logged: 1'), findsOneWidget);
  });

  testWidgets('Guest counters survive recreation on this device',
      (tester) async {
    await launch(tester);
    await tester.tap(find.text('Hydration'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a glass'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await launch(tester);
    expect(find.text('1'), findsOneWidget);
  });
}
