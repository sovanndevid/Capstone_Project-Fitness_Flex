import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import './history_page.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';

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
  bool _uploading = false;
  User? _user;
  String? _photoURL;

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
      final user = FirebaseAuth.instance.currentUser;
      setState(() {
        _user = user;
        _loading = true;
      });
      if (user == null) {
        _loading = false;
        if (mounted) setState(() {});
        return;
      }

      _nameCtrl.text = user.displayName ?? '';

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();

      // Read both variants; fall back to auth photoURL
      _photoURL = (data?['photoURL'] ?? data?['photoUrl'] ?? user.photoURL) as String?;
      _heightCtrl.text = (data?['height'] ?? '').toString();
      _weightCtrl.text = (data?['weight'] ?? '').toString();
      _activity = (data?['activity'] ?? 'moderate') as String;
      _nutritionGoal = (data?['nutritionGoal'] ?? 'maintain') as String;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_user == null) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() => _uploading = true);
      final ref =
          FirebaseStorage.instance.ref('users/${_user!.uid}/profile.jpg');

      final bytes = await picked.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      // Write both keys to keep HomePage (photoUrl) and this page (photoURL) in sync
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .set({'photoURL': url, 'photoUrl': url}, SetOptions(merge: true));

      await _user!.updatePhotoURL(url);

      if (!mounted) return;
      setState(() {
        _photoURL = url;
        _uploading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile photo updated!')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_user == null) return;

    try {
      final newName = _nameCtrl.text.trim();
      if (newName != (_user!.displayName ?? '')) {
        await _user!.updateDisplayName(newName);
      }

      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'height': _heightCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_heightCtrl.text.trim()),
        'weight': _weightCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_weightCtrl.text.trim()),
        'activity': _activity,
        'nutritionGoal': _nutritionGoal,
        // keep both keys present so HomePage sees the avatar
        if (_photoURL != null) 'photoURL': _photoURL,
        if (_photoURL != null) 'photoUrl': _photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Consistent light background like other pages
    final bg = const Color(0xFFF5F7FA);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: _navBar(context),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not signed in')),
        bottomNavigationBar: _navBar(context),
      );
    }

    final email = _user!.email ?? 'No email';
    final initialLetter = ((_user!.displayName?.isNotEmpty ?? false)
            ? _user!.displayName!.trim()[0]
            : email[0])
        .toUpperCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: _HeroHeaderProfile(
                name: _nameCtrl.text.trim().isEmpty
                    ? (_user!.displayName ?? 'Athlete')
                    : _nameCtrl.text.trim(),
                email: email,
                photoURL: _photoURL,
                fallbackLetter: initialLetter,
                uploading: _uploading,
                onChangePhoto: _uploading ? null : _uploadProfileImage,
              ),
            ),

            // Quick stats row (matches card style)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        icon: Icons.height,
                        label: 'Height',
                        value: _heightCtrl.text.trim().isEmpty
                            ? '-'
                            : '${_heightCtrl.text.trim()} cm',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStatCard(
                        icon: Icons.monitor_weight,
                        label: 'Weight',
                        value: _weightCtrl.text.trim().isEmpty
                            ? '-'
                            : '${_weightCtrl.text.trim()} kg',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStatCard(
                        icon: Icons.run_circle_outlined,
                        label: 'Activity',
                        value: _prettyActivity(_activity),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Profile form
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SectionCard(
                  title: 'Profile Details',
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: email,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _heightCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Height (cm)',
                                  prefixIcon: Icon(Icons.height),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _weightCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Weight (kg)',
                                  prefixIcon: Icon(Icons.monitor_weight),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Preferences (chip-like segment buttons)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SectionCard(
                  title: 'Preferences',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Activity Level'),
                      const SizedBox(height: 8),
                      _ChoiceRow<String>(
                        value: _activity,
                        onChanged: (v) => setState(() => _activity = v),
                        options: const [
                          ('sedentary', 'Sedentary', Icons.event_seat),
                          ('light', 'Light', Icons.directions_walk),
                          ('moderate', 'Moderate', Icons.run_circle),
                          ('active', 'Active', Icons.flash_on),
                          ('very_active', 'Very Active', Icons.fitness_center),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('Nutrition Goal'),
                      const SizedBox(height: 8),
                      _ChoiceRow<String>(
                        value: _nutritionGoal,
                        onChanged: (v) => setState(() => _nutritionGoal = v),
                        options: const [
                          ('bulk', 'Bulk', Icons.add_circle),
                          ('cut', 'Cut', Icons.remove_circle),
                          ('maintain', 'Maintain', Icons.radio_button_checked),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Today history (your original combined card logic)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SectionCard(
                  title: 'Today',
                  trailing: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HistoryPage(userId: _user!.uid),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('See all'),
                  ),
                  child: _TodayCombinedHistoryCard(
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
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                child: Column(
                  children: [
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
          ],
        ),
      ),
      bottomNavigationBar: _navBar(context),
    );
  }

  String _prettyActivity(String a) {
    switch (a) {
      case 'sedentary':
        return 'Sedentary';
      case 'light':
        return 'Light';
      case 'moderate':
        return 'Moderate';
      case 'active':
        return 'Active';
      case 'very_active':
        return 'Very Active';
      default:
        return a;
    }
  }

  Widget _navBar(BuildContext context) {
    return NavigationBar(
      selectedIndex: 4,
      onDestinationSelected: (i) {
        if (i == 4) return;
        switch (i) {
          case 0:
            Navigator.pushReplacementNamed(context, AppRouter.home);
            break;
          case 1:
            Navigator.pushReplacementNamed(context, AppRouter.workout);
            break;
          case 2:
            Navigator.pushReplacementNamed(context, AppRouter.nutrition);
            break;
          case 3:
            Navigator.pushReplacementNamed(context, AppRouter.progress);
            break;
          case 4:
          default:
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.fitness_center_outlined),
          selectedIcon: Icon(Icons.fitness_center),
          label: 'Workouts',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_outlined),
          selectedIcon: Icon(Icons.restaurant),
          label: 'Nutrition',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights),
          label: 'Progress',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

/* ------------------- UI Bits (styled like other pages) ------------------- */

class _HeroHeaderProfile extends StatelessWidget {
  const _HeroHeaderProfile({
    required this.name,
    required this.email,
    required this.photoURL,
    required this.fallbackLetter,
    required this.uploading,
    required this.onChangePhoto,
  });

  final String name;
  final String email;
  final String? photoURL;
  final String fallbackLetter;
  final bool uploading;
  final VoidCallback? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFEFF3FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.grey.shade300,
                backgroundImage:
                    (photoURL != null && photoURL!.isNotEmpty) ? NetworkImage(photoURL!) : null,
                child: (photoURL == null || photoURL!.isEmpty)
                    ? Text(
                        fallbackLetter,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      )
                    : null,
              ),
              if (uploading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black38,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Material(
                  color: theme.colorScheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onChangePhoto,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  const TextSpan(text: 'Your profile,\n'),
                  TextSpan(
                    text: name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextSpan(
                    text: '\n$email',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onChangePhoto,
            icon: const Icon(Icons.edit, color: Colors.black87),
            tooltip: 'Change photo',
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withOpacity(.10),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    this.title,
    this.trailing,
    required this.child,
  });

  final String? title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || trailing != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:
          const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<(T, String, IconData)> options;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final (val, label, icon) = opt;
        final selected = val == value;
        return InkWell(
          onTap: () => onChanged(val),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.blue.withOpacity(.10) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? Colors.blue.withOpacity(.35)
                    : Colors.grey.withOpacity(.25),
              ),
              boxShadow: [
                if (!selected)
                  BoxShadow(
                    color: Colors.black.withOpacity(.03),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: selected ? Colors.blue : Colors.black54),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.blue.shade700 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/* ---------------- TODAY COMBINED (your original logic) ---------------- */

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
    final start = _startOfDay(DateTime.now());
    final end = _nextDay(DateTime.now());

    final workoutsQ = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('workout_logs')
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('completedAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('completedAt', descending: true)
        .snapshots();

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
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: workoutsQ,
        builder: (context, workoutSnap) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: mealsQ,
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
                  child: Text("Failed to load today's history: $err"),
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
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            Chip(label: Text('${totalWorkoutMins.toStringAsFixed(0)} mins')),
                          if (totalWorkoutKcal > 0)
                            Chip(label: Text('${totalWorkoutKcal.toStringAsFixed(0)} kcal')),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...workouts.take(3).map((e) {
                        final details = [
                          if ((e['duration'] as double?) != null)
                            '${(e['duration'] as double).toStringAsFixed(0)} min',
                          if ((e['calories'] as double?) != null)
                            '${(e['calories'] as double).toStringAsFixed(0)} kcal',
                        ].where((s) => s.isNotEmpty).join(' • ');
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
                            Chip(label: Text('${totalMealKcal.toStringAsFixed(0)} kcal')),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...meals.take(3).map((e) {
                        final cals = (e['calories'] as double?);
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.restaurant),
                          title: Text(e['name'] as String),
                          subtitle: (cals == null) ? null : Text('${cals.toStringAsFixed(0)} kcal'),
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
