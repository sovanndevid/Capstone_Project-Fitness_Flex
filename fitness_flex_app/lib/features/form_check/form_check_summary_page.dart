import 'package:flutter/material.dart';

class FormCheckSummaryPage extends StatelessWidget {
  const FormCheckSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map;

    final exercise     = (args['exercise'] ?? 'Exercise') as String;
    final reps         = (args['reps'] ?? 0) as int;
    final goodFrames   = (args['goodFrames'] ?? 0) as int;
    final scoredFrames = (args['scoredFrames'] ?? 0) as int;
    final goodPct = scoredFrames > 0 ? (goodFrames / scoredFrames * 100) : 0.0;
    final fails = (args['fails'] ?? const <String,int>{}) as Map<String,int>;
    final timeline = (args['timeline'] ?? const <String>[]) as List<String>;

    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        cardTheme: CardThemeData(
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text('Session Summary – $exercise')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _kpi('Reps', '$reps'),
                      _kpi('Good-form', '${goodPct.toStringAsFixed(0)}%'),
                      _kpi('Frames', '$scoredFrames'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Common issues', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    _issueRow('Back not upright', fails['back'] ?? 0),
                    _issueRow('Depth (hip below knee)', fails['depth'] ?? 0),
                    _issueRow('Knees over toes', fails['knee'] ?? 0),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Timeline', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 6, runSpacing: 6,
                    children: timeline.map((t) {
                      final good = t == 'G';
                      return Container(
                        width: 18, height: 10,
                        decoration: BoxDecoration(
                          color: good ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpi(String label, String value) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.grey)),
    ],
  );

  Widget _issueRow(String name, int count) => ListTile(
    dense: true,
    title: Text(name),
    trailing: Text('x$count'),
  );
}