import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:fitness_flex_app/data/models/workout_log.dart';
import 'package:fitness_flex_app/data/models/workout_model.dart';

class WorkoutLogRepository {
  WorkoutLogRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _col() {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Not signed in');
    }
    return _db.collection('users').doc(uid).collection('workout_logs');
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      final m = RegExp(r'\d+').firstMatch(v);
      return m != null ? int.tryParse(m.group(0)!) ?? 0 : 0;
    }
    return 0;
  }

  Future<void> logWorkout(Workout w) async {
    final uid = _uid;
    if (uid == null) throw StateError('Please sign in to log workouts');

    final duration = _toInt((w as dynamic).duration);
    final calories = _toInt((w as dynamic).calories);

    // Use a concrete timestamp so it appears in today's stream immediately
    final now = Timestamp.now();

    final ref = await _col().add({
      'workoutId': (w as dynamic).id ?? '',
      'title': (w as dynamic).title ?? '',
      'duration': duration,
      'calories': calories,
      'completedAt': now,
      // Optional: for TTL cleanup later
      // 'expireAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('[WORKOUT_LOG] added ${ref.id} for uid=$uid');
  }

  Future<List<WorkoutLog>> getTodayLogs() async {
    final uid = _uid;
    if (uid == null) return [];
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final qs = await _col()
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('completedAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('completedAt', descending: true)
        .get();

    return qs.docs.map(WorkoutLog.fromDoc).toList();
  }

  Stream<List<WorkoutLog>> streamTodayLogs() {
    final uid = _uid;
    if (uid == null) return const Stream<List<WorkoutLog>>.empty();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return _col()
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('completedAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map(WorkoutLog.fromDoc).toList());
  }
}