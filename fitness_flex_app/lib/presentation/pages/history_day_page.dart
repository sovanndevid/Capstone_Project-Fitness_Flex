import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HistoryDayPage extends StatelessWidget {
  const HistoryDayPage({super.key, required this.userId, required this.day});

  final String userId;
  final DateTime day;

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _nextDay(DateTime d) => _startOfDay(d).add(const Duration(days: 1));
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

  @override
  Widget build(BuildContext context) {
    final start = _startOfDay(day);
    final end = _nextDay(day);

    final workoutsQ = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('workout_logs')
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('completedAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('completedAt', descending: true)
        .snapshots();

    // CHANGE: meals use 'timestamp'
    final mealsQ = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('meals')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text('History ${_fmtDate(start)}')),
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
                return Center(child: Text('Failed to load: $err'));
              }

              final wDocs = workoutSnap.data?.docs ?? const [];
              final mDocs = mealsSnap.data?.docs ?? const [];

              final workouts = wDocs.map((d) {
                final x = d.data();
                return {
                  'name': (x['title'] ?? x['name'] ?? 'Workout').toString(),
                  'duration': _toDouble(x['duration']),
                  'calories': _toDouble(x['calories']),
                  'reps': x['reps'],
                  'sets': x['sets'],
                };
              }).toList();

              final meals = mDocs.map((d) {
                final x = d.data();
                return {
                  'name': (x['name'] ?? x['title'] ?? 'Meal').toString(),
                  'calories': _toDouble(x['calories']),
                };
              }).toList();

              final totalWorkoutMins = workouts.fold<double>(
                0,
                (s, e) => s + (e['duration'] as double? ?? 0),
              );
              final totalWorkoutKcal = workouts.fold<double>(
                0,
                (s, e) => s + (e['calories'] as double? ?? 0),
              );
              final totalMealKcal = meals.fold<double>(
                0,
                (s, e) => s + (e['calories'] as double? ?? 0),
              );

              final children = <Widget>[
                // Summary chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('${workouts.length} workouts')),
                      Chip(label: Text('${meals.length} meals')),
                      if (totalWorkoutMins > 0)
                        Chip(
                          label: Text(
                            '${totalWorkoutMins.toStringAsFixed(0)} mins',
                          ),
                        ),
                      if (totalWorkoutKcal + totalMealKcal > 0)
                        Chip(
                          label: Text(
                            '${(totalWorkoutKcal + totalMealKcal).toStringAsFixed(0)} kcal',
                          ),
                        ),
                    ],
                  ),
                ),

                // Workouts section
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Workouts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                if (workouts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('No workouts logged'),
                  )
                else
                  ...workouts.map((e) {
                    final details = [
                      if (e['sets'] != null) '${e['sets']} sets',
                      if (e['reps'] != null) '${e['reps']} reps',
                      if ((e['duration'] as double?) != null)
                        '${(e['duration'] as double).toStringAsFixed(0)} min',
                      if ((e['calories'] as double?) != null)
                        '${(e['calories'] as double).toStringAsFixed(0)} kcal',
                    ].join(' • ');
                    return ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text(e['name'] as String),
                      subtitle: details.isEmpty ? null : Text(details),
                    );
                  }),

                // Nutrition section
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Nutrition',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                if (meals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('No meals logged'),
                  )
                else
                  ...meals.map((e) {
                    final details = [
                      if ((e['calories'] as double?) != null)
                        '${(e['calories'] as double).toStringAsFixed(0)} kcal',
                    ].join(' • ');
                    return ListTile(
                      leading: const Icon(Icons.restaurant),
                      title: Text(e['name'] as String),
                      subtitle: details.isEmpty ? null : Text(details),
                    );
                  }),

                const SizedBox(height: 12),
              ];

              return ListView(children: children);
            },
          );
        },
      ),
    );
  }
}
