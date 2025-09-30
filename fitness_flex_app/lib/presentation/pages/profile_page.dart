import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './history_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  String _activity = 'moderate';
  String _nutritionGoal = 'maintain';
  bool _loading = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      setState(() {
        _user = user;
        _loading = true;
      });
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      _nameCtrl.text = user.displayName ?? '';

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      _heightCtrl.text = (data?['height'] ?? '').toString();
      _weightCtrl.text = (data?['weight'] ?? '').toString();
      _activity = (data?['activity'] ?? 'moderate') as String;
      _nutritionGoal = (data?['nutritionGoal'] ?? 'maintain') as String;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_user == null) return;

    try {
      // Update display name in FirebaseAuth
      if (_nameCtrl.text.trim() != (_user!.displayName ?? '')) {
        await _user!.updateDisplayName(_nameCtrl.text.trim());
      }

      // Merge profile fields into Firestore
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'height': _heightCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_heightCtrl.text.trim()),
        'weight': _weightCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_weightCtrl.text.trim()),
        'activity': _activity,
        'nutritionGoal': _nutritionGoal,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      setState(() {}); // refresh UI
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pop(); // go back after sign out
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not signed in')),
      );
    }

    final email = _user!.email ?? 'No email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Text(
                    (_user!.displayName?.isNotEmpty == true
                            ? _user!.displayName!.trim()[0]
                            : email[0])
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email (read-only)
                TextFormField(
                  initialValue: email,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),

                // Display name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 16),

                // Height
                TextFormField(
                  controller: _heightCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    prefixIcon: Icon(Icons.height),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Weight
                TextFormField(
                  controller: _weightCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Activity
                DropdownButtonFormField<String>(
                  value: _activity,
                  decoration: const InputDecoration(
                    labelText: 'Activity Level',
                    prefixIcon: Icon(Icons.directions_run),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'sedentary',
                      child: Text('Sedentary'),
                    ),
                    DropdownMenuItem(value: 'light', child: Text('Light')),
                    DropdownMenuItem(
                      value: 'moderate',
                      child: Text('Moderate'),
                    ),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'very_active',
                      child: Text('Very Active'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _activity = v ?? 'moderate'),
                ),
                const SizedBox(height: 16),

                // Nutrition goal
                DropdownButtonFormField<String>(
                  value: _nutritionGoal,
                  decoration: const InputDecoration(
                    labelText: 'Nutrition Goal',
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'bulk', child: Text('Bulk')),
                    DropdownMenuItem(value: 'cut', child: Text('Cut')),
                    DropdownMenuItem(
                      value: 'maintain',
                      child: Text('Maintain'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _nutritionGoal = v ?? 'maintain'),
                ),
                const SizedBox(height: 24),

                _TodayCombinedHistoryCard(
                  userId: _user!.uid,
                  onSeeAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryPage(userId: _user!.uid),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayCombinedHistoryCard extends StatelessWidget {
  const _TodayCombinedHistoryCard({
    required this.userId,
    required this.onSeeAll,
  });

  final String userId;
  final VoidCallback onSeeAll;

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _nextDay(DateTime d) => _startOfDay(d).add(const Duration(days: 1));

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
    final now = DateTime.now();
    final start = _startOfDay(now);
    final end = _nextDay(now);

    final workoutsQ = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('workout_logs')
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('completedAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('completedAt', descending: true)
        .snapshots();

    // CHANGE: meals use 'timestamp' (not loggedAt)
    final mealsQ = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('meals')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: workoutsQ,
        builder: (context, workoutSnap) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: mealsQ, // use the single meals stream
            builder: (context, mealsSnap) {
              if (workoutSnap.connectionState == ConnectionState.waiting ||
                  mealsSnap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (workoutSnap.hasError || mealsSnap.hasError) {
                final err = workoutSnap.error ?? mealsSnap.error;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load today\'s history: $err'),
                );
              }

              final wDocs = workoutSnap.data?.docs ?? const [];
              final mDocs = mealsSnap.data?.docs ?? const [];

              final workouts = wDocs.map((d) {
                final x = d.data();
                return {
                  'name': (x['title'] ?? x['name'] ?? 'Workout').toString(),
                  'duration': _toDouble(x['duration']),
                  'calories': _toDouble(x['calories']),
                };
              }).toList();

              // Meals from 'meals' by timestamp
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

              Widget sectionTitle(String text) => Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Workouts
                    sectionTitle('Workouts'),
                    if (workouts.isEmpty)
                      const Text('No workouts logged today')
                    else ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text('${workouts.length} workouts')),
                          if (totalWorkoutMins > 0)
                            Chip(
                              label: Text(
                                '${totalWorkoutMins.toStringAsFixed(0)} mins',
                              ),
                            ),
                          if (totalWorkoutKcal > 0)
                            Chip(
                              label: Text(
                                '${totalWorkoutKcal.toStringAsFixed(0)} kcal',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...workouts.take(3).map((e) {
                        final details = [
                          if ((e['duration'] as double?) != null)
                            '${(e['duration'] as double).toStringAsFixed(0)} min',
                          if ((e['calories'] as double?) != null)
                            '${(e['calories'] as double).toStringAsFixed(0)} kcal',
                        ].join(' • ');
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.fitness_center),
                          title: Text(e['name'] as String),
                          subtitle: details.isEmpty ? null : Text(details),
                        );
                      }),
                    ],

                    const SizedBox(height: 16),

                    // Nutrition
                    sectionTitle('Nutrition'),
                    if (meals.isEmpty)
                      const Text('No meals logged today')
                    else ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text('${meals.length} meals')),
                          if (totalMealKcal > 0)
                            Chip(
                              label: Text(
                                '${totalMealKcal.toStringAsFixed(0)} kcal',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...meals.take(3).map((e) {
                        final details = [
                          if ((e['calories'] as double?) != null)
                            '${(e['calories'] as double).toStringAsFixed(0)} kcal',
                        ].join(' • ');
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.restaurant),
                          title: Text(e['name'] as String),
                          subtitle: details.isEmpty ? null : Text(details),
                        );
                      }),
                    ],

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onSeeAll,
                        icon: const Icon(Icons.history),
                        label: const Text('See all history'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
