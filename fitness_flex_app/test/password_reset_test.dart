import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_flex_app/presentation/pages/forget_password_page.dart';

Widget screen(PasswordResetSender send) => MaterialApp(
  home: Scaffold(
    body: Builder(builder: (context) => TextButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ForgotPasswordPage(sendResetEmail: send),
      )),
      child: const Text('Open reset'),
    )),
  ),
);

Future<void> openReset(WidgetTester tester, PasswordResetSender send) async {
  await tester.pumpWidget(screen(send));
  await tester.tap(find.text('Open reset'));
  await tester.pumpAndSettle();
  expect(find.text('Send Reset Link'), findsOneWidget);
}

void main() {
  testWidgets('Rejects missing or malformed email without using the API',
      (tester) async {
    var requests = 0;
    await openReset(tester, (email) async {requests++;});
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();
    expect(find.text('Please enter your email'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'invalid@domain');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();
    expect(find.text('Please enter a valid email address'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('Valid address uses injected sender and navigates on success',
      (tester) async {
    String? sent;
    await openReset(tester, (email) async {sent=email;});
    await tester.enterText(find.byType(TextFormField), '  demo@example.com ');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();
    expect(sent, 'demo@example.com');
    expect(find.text('Open reset'), findsOneWidget);
    expect(find.textContaining('If this email has a FitnessFlex account'), findsOneWidget);
  });

  testWidgets('Firebase network error is readable and preserves the screen',
      (tester) async {
    await openReset(tester, (email) async {
      throw FirebaseAuthException(code: 'network-request-failed');
    });
    await tester.enterText(find.byType(TextFormField), 'demo@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();
    expect(find.textContaining('Connection unavailable'), findsOneWidget);
    expect(find.text('Send Reset Link'), findsOneWidget);
  });

  testWidgets('Unexpected type errors never appear in user-facing feedback',
      (tester) async {
    await openReset(tester, (email) async {
      throw TypeError();
    });
    await tester.enterText(find.byType(TextFormField), 'demo@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();
    expect(find.textContaining('could not send the reset email'), findsOneWidget);
    expect(find.textContaining('TypeError'), findsNothing);
  });

  testWidgets('Pending reset blocks duplicate submissions', (tester) async {
    final done = Completer<void>();
    var calls=0;
    await openReset(tester, (email) async { calls++; await done.future; });
    await tester.enterText(find.byType(TextFormField), 'demo@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(calls, 1);
    done.complete();
    await tester.pumpAndSettle();
    expect(calls, 1);
  });
}
