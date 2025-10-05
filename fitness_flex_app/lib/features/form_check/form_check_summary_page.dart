import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FormCheckSummaryPage extends StatefulWidget {
  const FormCheckSummaryPage({super.key});

  @override
  State<FormCheckSummaryPage> createState() => _FormCheckSummaryPageState();
}

class _FormCheckSummaryPageState extends State<FormCheckSummaryPage> {
  String? _feedback;
  bool _loading = false;

  // API key
  static const String _apiKey = "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";

  Future<void> _getAIAdvice(Map<String, dynamic> summary) async {
    setState(() => _loading = true);

    try {
      final body = {
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a professional fitness coach. Provide short, encouraging, and clear feedback about the user's exercise form. Keep your response in English only. Avoid technical jargon."
          },
          {
            "role": "user",
            "content": """
Summarize and give motivational advice for this squat session:
Exercise: ${summary['exercise']}
Reps: ${summary['reps']}
Overall Score: ${summary['overallScore']}
Component Scores: ${jsonEncode(summary['components'])}
Common Issues: ${jsonEncode(summary['fails'])}
"""
          }
        ]
      };

      final res = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey",
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final msg = data['choices'][0]['message']['content'];
        setState(() => _feedback = msg);
      } else {
        setState(() => _feedback = "Failed to get feedback: ${res.body}");
      }
    } catch (e) {
      setState(() => _feedback = "Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map;

    final exercise = (args['exercise'] ?? 'Exercise') as String;
    final reps = (args['reps'] ?? 0) as int;
    final overallScore = (args['overallScore'] ?? 0.0) as double;
    final components = (args['components'] ?? const <String, double>{}) as Map<String, double>;
    final fails = (args['fails'] ?? const <String, int>{}) as Map<String, int>;

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Session Summary – $exercise')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏋️ Overall Score
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Overall Score', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (overallScore / 10).clamp(0, 1),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(6),
                      color: overallScore >= 8
                          ? Colors.green
                          : (overallScore >= 6 ? Colors.orange : Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      overallScore.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text('Reps Completed: $reps'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ⚙️ Component Breakdown
            Text('Form Component Scores', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: components.entries.map((e) {
                    final label = e.key[0].toUpperCase() + e.key.substring(1);
                    final val = e.value;
                    final color = val >= 8
                        ? Colors.green
                        : (val >= 6 ? Colors.orange : Colors.red);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(label)),
                          Expanded(
                            flex: 5,
                            child: LinearProgressIndicator(
                              value: val / 10,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                              color: color,
                              backgroundColor: Colors.grey[200],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(val.toStringAsFixed(1)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ❌ Common Issues
            Text('Common Issues', style: theme.textTheme.titleMedium),
            Card(
              child: Column(
                children: fails.entries.map((e) {
                  return ListTile(
                    dense: true,
                    title: Text(e.key),
                    trailing: Text('x${e.value}'),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // 🤖 AI FEEDBACK
            if (_feedback != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _feedback!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // 🧠 Get AI Feedback Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading
                    ? null
                    : () => _getAIAdvice({
                          'exercise': exercise,
                          'reps': reps,
                          'overallScore': overallScore,
                          'components': components,
                          'fails': fails,
                        }),
                icon: const Icon(Icons.psychology_alt),
                label: Text(_loading ? 'Generating Feedback...' : 'Get AI Feedback'),
              ),
            ),
            const SizedBox(height: 16),

            // 🔁 Done button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
