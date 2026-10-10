import 'dart:html' as html;
import 'package:flutter/material.dart';

/// Web replacement for the Android/iOS-only ML Kit camera implementation.
/// Movement inference currently runs in the separate browser Motion Lab.
class FormCheckerScreen extends StatelessWidget {
  const FormCheckerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Form Check · Flutter Web')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 510),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.accessibility_new, size: 62, color: accent),
                    const SizedBox(height: 16),
                    const Text('Motion Intelligence', style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 24,
                    ), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    const Text(
                      'FitnessFlex is running as a genuine Flutter Web app. '
                      'Its original Google ML Kit pose detector works on '
                      'Android and iOS, not Flutter Web. '
                      'Use the companion browser Motion Lab for the squat '
                      'tracking prototype and movement replay.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: () => html.window.open(
                        'https://sovanndevid.xyz/fitnessflex/', '_blank'),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Motion Lab'),
                    ),
                    const SizedBox(height: 12),
                    const Text('Experimental fitness feedback, not clinical advice.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
