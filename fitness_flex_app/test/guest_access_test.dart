import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';
import 'package:fitness_flex_app/presentation/pages/guest_access_page.dart';

void main() {
  testWidgets('Anonymous sign-in opens the existing real app route',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: GuestAccessPage(startSession: () async { calls++; }),
      routes: {
        AppRouter.home: (_) => const Scaffold(body: Text('Real FitnessFlex Home')),
      },
    ));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Real FitnessFlex Home'), findsOneWidget);
  });

  testWidgets('Anonymous authentication disabled gives clear guidance',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GuestAccessPage(startSession: () async {
        throw FirebaseAuthException(code: 'operation-not-allowed');
      }),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('enable Anonymous'), findsOneWidget);
    expect(find.text('Retry Guest Access'), findsOneWidget);
    expect(find.text('Open limited offline preview'), findsOneWidget);
  });

  testWidgets('Guest can retry after a network error', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: GuestAccessPage(startSession: () async {
        calls++;
        if (calls == 1) {
          throw FirebaseAuthException(code: 'network-request-failed');
        }
      }),
      routes: {
        AppRouter.home: (_) => const Scaffold(body: Text('Real app unlocked')),
      },
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Check your connection'), findsOneWidget);
    await tester.tap(find.text('Retry Guest Access'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Real app unlocked'), findsOneWidget);
  });
}
