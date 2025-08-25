import 'package:flutter_test/flutter_test.dart';
import 'package:conquer_gym_app/main.dart';

void main() {
  testWidgets('App loads and shows home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ConquerGymApp());

    // Verify that "Conquer Gym" text from AppBar is present.
    expect(find.text('Conquer Gym'), findsOneWidget);

    // Verify that the "Target Muscles" section appears.
    expect(find.text('Target Muscles'), findsOneWidget);

    // Verify that the "Workouts" section appears.
    expect(find.text('Workouts'), findsOneWidget);
  });
}
