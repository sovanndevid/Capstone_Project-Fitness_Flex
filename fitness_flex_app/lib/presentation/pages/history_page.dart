import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'history_day_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.userId});

  final String userId;

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      final m = RegExp(r'-?\d+(\.\d+)?').firstMatch(v);
      if (m != null) return double.tryParse(m.group(0)!);
    }
    return null;
  }

  DateTime _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate().toLocal();
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed.toLocal();
    }
    if (v is int) {
      // if someone stored millis since epoch
      final dt = DateTime.fromMillisecondsSinceEpoch(v, isUtc: true).toLocal();
      return dt;
    }
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final workoutsQ = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('workout_logs')
        .orderBy('completedAt', descending: true)
        .limit(300)
        .snapshots();

    // CHANGE: meals use 'timestamp'
    final mealsQ = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('meals')
        .orderBy('timestamp', descending: true)
        .limit(300)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: workoutsQ,
        builder: (context, workoutSnap) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: mealsQ,
            builder: (context, mealsSnap) {
              if (workoutSnap.connectionState == ConnectionState.waiting ||
                  mealsSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (workoutSnap.hasError || mealsSnap.hasError) {
                final err = workoutSnap.error ?? mealsSnap.error;
                return Center(child: Text('Failed to load history: $err'));
              }

              final wDocs = workoutSnap.data?.docs ?? const [];
              final mDocs = mealsSnap.data?.docs ?? const [];

              // Flatten, normalize
              final all = <Map<String, dynamic>>[
                ...wDocs.map((d) {
                  final x = d.data();
                  return {
                    'type': 'workout',
                    'name': (x['title'] ?? x['name'] ?? 'Workout').toString(),
                    'createdAt': x['completedAt'],
                    'calories': _toDouble(x['calories']),
                    'duration': _toDouble(x['duration']),
                  };
                }),
                ...mDocs.map((d) {
                  final x = d.data();
                  return {
                    'type': 'nutrition',
                    'name': (x['name'] ?? x['title'] ?? 'Meal').toString(),
                    'createdAt': x['timestamp'], // CHANGE: group by timestamp
                    'calories': _toDouble(x['calories']),
                  };
                }),
              ];

              // Group by day
              final Map<DateTime, List<Map<String, dynamic>>> byDay = {};
              for (final e in all) {
                final dt = _toDate(e['createdAt']);
                final key = _startOfDay(dt);
                byDay.putIfAbsent(key, () => []).add(e);
              }

              final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
              if (days.isEmpty) {
                return const Center(child: Text('No history yet'));
              }

              return ListView.separated(
                itemCount: days.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final day = days[i];
                  final items = byDay[day]!;
                  final totalCalories = items.fold<double>(
                    0,
                    (sum, e) => sum + (_toDouble(e['calories']) ?? 0),
                  );
                  final totalMinutes = items.fold<double>(
                    0,
                    (sum, e) => sum + (_toDouble(e['duration']) ?? 0),
                  );
                  final workoutsCount = items
                      .where((e) => e['type'] == 'workout')
                      .length;
                  final mealsCount = items
                      .where((e) => e['type'] == 'nutrition')
                      .length;

                  final subtitle = [
                    if (workoutsCount > 0) '$workoutsCount workouts',
                    if (mealsCount > 0) '$mealsCount meals',
                    if (totalMinutes > 0)
                      '${totalMinutes.toStringAsFixed(0)} mins',
                    if (totalCalories > 0)
                      '${totalCalories.toStringAsFixed(0)} kcal',
                  ].join(' • ');

                  return ListTile(
                    title: Text(_fmtDate(day)),
                    subtitle: subtitle.isEmpty ? null : Text(subtitle),
                    leading: const Icon(Icons.calendar_today),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              HistoryDayPage(userId: userId, day: day),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
