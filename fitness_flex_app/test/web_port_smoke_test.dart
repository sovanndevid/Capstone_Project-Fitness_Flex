import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_flex_app/presentation/pages/forget_password_page.dart';
import 'package:fitness_flex_app/presentation/pages/chat_screen_web.dart';

// Web-safe widgets have no secret-bearing backend requests until reviewed.
void main() {
  testWidgets('Password reset validates malformed input before contacting Firebase', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
    expect(find.text('Forgot Password'), findsOneWidget);
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();
    expect(find.text('Please enter your email'), findsOneWidget);
  });

  testWidgets('Web chat clearly communicates restricted availability', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatScreen()));
    expect(find.text('FitnessFlex Coach'), findsOneWidget);
    expect(find.textContaining('currently available in the mobile app'), findsOneWidget);
  });
}
