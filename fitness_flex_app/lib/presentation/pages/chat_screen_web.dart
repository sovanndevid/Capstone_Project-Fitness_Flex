import 'package:flutter/material.dart';

/// The original chat uses a mobile-oriented image flow and an external
/// backend. Disable it in the public web port until a reviewed web integration
/// is available; do not ship API tokens or silently forward user content.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('FitnessFlex Coach')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'The AI chat feature is currently available in the mobile app. '
          'The Flutter Web port includes workouts, nutrition and progress. '
          'A web-safe chat backend can be connected separately after review.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
