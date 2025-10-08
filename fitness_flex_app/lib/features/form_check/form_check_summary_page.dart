import 'dart:convert';
import 'dart:io';
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

  // Hard-coded for project/dev. Do NOT ship a live app like this.
  static const String _apiKey = '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';

  /// Reduce the analyzer JSON size (cheaper, faster).
  Map<String, dynamic> _thinSession(Map<String, dynamic> s) => {
        'fps': s['fps'],
        'reps_detected': s['reps_detected'],
        'overall_score_mean': s['overall_score_mean'],
        'overall_score_stdev': s['overall_score_stdev'],
        'stance_ref': s['stance_ref'],
        'reps': (s['reps'] is List ? (s['reps'] as List) : const [])
            .map((r) {
              final rMap = (r is Map) ? r : const {};
              final m = (rMap['metrics'] is Map) ? rMap['metrics'] as Map : const {};
              return {
                'rep_id': rMap['rep_id'],
                'score': rMap['score'],
                'score_components': rMap['score_components'],
                'view': rMap['view'],
                'metrics': {
                  'knee_angle_min': m['knee_angle_min'],
                  'rom_knee': m['rom_knee'],
                  'torso_lean_bottom_deg': m['torso_lean_bottom_deg'],
                  'tempo_ms': m['tempo_ms'],
                  'stability': m['stability'],
                  'valgus_drop_pct': m['valgus_drop_pct'],
                  'symmetry_rom_diff_pct': m['symmetry_rom_diff_pct'],
                },
                'faults': rMap['faults'],
              };
            })
            .toList(),
      };

  Future<void> _getAIAdvice({
    required Map<String, dynamic> sessionJson,
    required String exercise,
  }) async {
    if (sessionJson.isEmpty) {
      setState(() => _feedback = 'No session JSON found.');
      return;
    }

    setState(() => _loading = true);

    const systemPrompt = '''
You are a supportive strength coach. Given JSON from a squat form analysis, write 90–140 words.
Priorities: depth, torso lean, stability, tempo, ROM. If front-view data is present, include valgus & symmetry; otherwise skip them.
Be specific, encouraging, and end with 1–2 concrete tips. English only.
''';

    final userContent = jsonEncode({
      'exercise': exercise,
      'session': _thinSession(sessionJson),
    });

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'temperature': 0.6,
      'max_tokens': 250,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userContent},
      ],
    });

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    Future<http.Response> _send() => http
        .post(
          uri,
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $_apiKey',
            HttpHeaders.contentTypeHeader: 'application/json',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 25));

    try {
      var res = await _send();
      if (res.statusCode == 429 || res.statusCode >= 500) {
        await Future.delayed(const Duration(milliseconds: 800));
        res = await _send();
      }
      if (res.statusCode == 429 || res.statusCode >= 500) {
        await Future.delayed(const Duration(milliseconds: 1200));
        res = await _send();
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        final msg = (data['choices']?[0]?['message']?['content'] ?? '').toString().trim();
        setState(() => _feedback = msg.isEmpty ? 'No feedback returned.' : msg);
      } else if (res.statusCode == 401) {
        setState(() => _feedback = 'Unauthorized: check API key.');
      } else if (res.statusCode == 429) {
        setState(() => _feedback = 'Rate limited. Try again shortly.');
      } else {
        setState(() => _feedback = 'API error ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      setState(() => _feedback = 'Network error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------- Helpers to coerce route args safely ----------
  T _as<T>(Object? v, T fallback) => (v is T) ? v : fallback;

  Map<String, double> _coerceMapDouble(Object? m) {
    if (m is Map) {
      return m.map<String, double>((k, v) =>
          MapEntry(k.toString(), (v is num) ? v.toDouble() : 0.0));
    }
    return <String, double>{};
  }

  Map<String, int> _coerceMapInt(Object? m) {
    if (m is Map) {
      return m.map<String, int>((k, v) =>
          MapEntry(k.toString(), (v is num) ? v.toInt() : 0));
    }
    return <String, int>{};
  }

  @override
  Widget build(BuildContext context) {
    // Route args (untyped by default) → coerce safely
    final rawArgs = _as<Map>(ModalRoute.of(context)?.settings.arguments, const {}) as Map;

    final exercise = _as<String>(rawArgs['exercise'], 'Exercise');
    final reps = (_as<num>(rawArgs['reps'], 0)).toInt();
    final overallScore = (_as<num>(rawArgs['overallScore'], 0)).toDouble();

    final components = _coerceMapDouble(rawArgs['components']);
    final fails = _coerceMapInt(rawArgs['fails']);

    // Full analyzer JSON passed from capture screen
    final sessionJson =
        (rawArgs['sessionJson'] is Map) ? rawArgs['sessionJson'] as Map<String, dynamic> : <String, dynamic>{};

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
                    final label = e.key.isEmpty
                        ? 'Component'
                        : e.key[0].toUpperCase() + e.key.substring(1);
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
                              value: (val / 10).clamp(0, 1),
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
                onPressed: _loading || sessionJson.isEmpty
                    ? null
                    : () => _getAIAdvice(
                          sessionJson: sessionJson,
                          exercise: exercise,
                        ),
                icon: const Icon(Icons.psychology_alt),
                label: Text(_loading
                    ? 'Generating Feedback...'
                    : (sessionJson.isEmpty ? 'No Session Data' : 'Get AI Feedback')),
              ),
            ),
            const SizedBox(height: 16),

            // 🔁 Done
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
