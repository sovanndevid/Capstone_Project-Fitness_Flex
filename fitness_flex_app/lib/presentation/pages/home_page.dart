import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fitness_flex_app/core/themes/app_theme.dart';
import 'chat_screen.dart';
import './profile_page.dart';

import 'package:fitness_flex_app/data/repositories/nutrition_repository.dart';
import 'package:fitness_flex_app/data/models/nutrition_goal.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  Map<String, dynamic>? _userData;
  bool _loading = true;

  final NutritionRepository _nutritionRepository = NutritionRepository();
  late Future<Map<String, double>> _todaySummaryFuture;
  late Future<NutritionGoal> _goalFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNutritionFutures();
  }

  void _loadNutritionFutures() {
    _todaySummaryFuture = _nutritionRepository.getTodayNutritionSummary();
    _goalFuture = _nutritionRepository.getNutritionGoal();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();
        if (!mounted) return;
        setState(() {
          _userData = doc.data() ?? {};
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user profile')),
        );
      }
    }
  }

  void _onNavTap(int i) {
    if (i == _selectedIndex) return;
    setState(() => _selectedIndex = i);
    switch (i) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, AppRouter.workout);
        break;
      case 2:
        Navigator.pushNamed(context, AppRouter.nutrition);
        break;
      case 3:
        Navigator.pushNamed(context, AppRouter.progress);
        break;
      case 4:
        Navigator.pushNamed(context, AppRouter.profile);
        break;
    }
  }

  // ---- helper to read values with alternate keys ----
  double _read(Map<String, double> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null) return v.toDouble();
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final authUser = FirebaseAuth.instance.currentUser;
    final rawName = _userData?['displayName'] ??
        _userData?['name'] ??
        authUser?.displayName ??
        (authUser?.email != null ? authUser!.email!.split('@').first : 'Athlete');
    final name = rawName.toString().trim().capitalize();

    final lightTheme = baseTheme.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: baseTheme.colorScheme.copyWith(
        brightness: Brightness.light,
        background: Colors.white,
        surface: Colors.white,
        onBackground: Colors.black,
        onSurface: Colors.black,
      ),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
    );

    return Theme(
      data: lightTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: () async {
            _loadNutritionFutures();
            await _loadUserData();
            setState(() {});
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeroHeader(
                  name: name,
                  avatarUrl: _userData?['photoURL'],
                  onProfile: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const ProfilePage())),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: FutureBuilder(
                    future: Future.wait([_todaySummaryFuture, _goalFuture]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _LoadingRow();
                      }
                      if (!snapshot.hasData || snapshot.hasError) {
                        return const Text(
                          'Unable to load today\'s nutrition',
                          style: TextStyle(color: Colors.redAccent),
                        );
                      }

                      final today = snapshot.data![0] as Map<String, double>;
                      final goal = snapshot.data![1] as NutritionGoal;

                      // Robust reads (works with 'calories/kcal/energy' and 'fat/fats')
                      final double cals    = (today['calories'] ?? 0).toDouble();
                      final double protein = (today['protein']  ?? 0).toDouble();
                      final double carbs   = (today['carbs']    ?? 0).toDouble();
                      final double fats     = (today['fats']      ?? 0).toDouble();
                      // quick visibility while testing
                      assert(() {
                        debugPrint('HOME today=$today '
                            '-> cals=$cals p=$protein c=$carbs f=$fats '
                            'goal(cal=${goal.calories}, p=${goal.protein}, c=${goal.carbs}, f=${goal.fats})');
                        return true;
                      }());

                      final double calGoal = goal.dailyCalories; // mirrors NutritionPage
                      final double pct = calGoal > 0 ? (cals / calGoal).clamp(0.0, 1.0).toDouble() : 0.0;
                      return Column(
                        children: [
                          _CaloriesRing(
                            percent: pct,
                            consumed: cals,
                            goal: calGoal,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _MacroCard(
                                  label: 'Protein',
                                  value: protein,
                                  goal: goal.dailyProtein,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MacroCard(
                                  label: 'Carbs',
                                  value: carbs,
                                  goal: goal.dailyCarbs,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MacroCard(
                                  label: 'Fats',
                                  value: fats,
                                  goal: goal.dailyFat, 
                                  color: Colors.pink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Use your existing Form Check feature routes
                          _FormCheckShortcutCard(
                            onOpen: () =>
                                Navigator.pushNamed(context, AppRouter.formCheckMenu),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _QuickActions(
                    onWorkouts: () => Navigator.pushNamed(context, AppRouter.workout),
                    onNutrition: () => Navigator.pushNamed(context, AppRouter.nutrition),
                    onProgress: () => Navigator.pushNamed(context, AppRouter.progress),
                    onChat: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const ChatScreen())),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Recent Activity',
                  actionLabel: 'See all',
                  onAction: () => Navigator.pushNamed(context, AppRouter.progress),
                ),
              ),
              SliverList.builder(
                itemCount: 4,
                itemBuilder: (_, i) => _ActivityTile(
                  title: i == 0
                      ? 'Logged Breakfast'
                      : i == 1
                          ? 'Completed Upper Body Workout'
                          : i == 2
                              ? 'Updated Water Intake'
                              : 'Set New Goal',
                  subtitle: i == 1 ? '45 min • 6 exercises' : 'Today',
                  icon: i == 1 ? Icons.fitness_center : Icons.check_circle,
                  color: i == 1 ? Colors.deepPurple : Colors.teal,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onNavTap,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(Icons.fitness_center),
                label: 'Workouts'),
            NavigationDestination(
                icon: Icon(Icons.restaurant_outlined),
                selectedIcon: Icon(Icons.restaurant),
                label: 'Nutrition'),
            NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Progress'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

/* ----------------- HERO HEADER ----------------- */
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.name,
    this.avatarUrl,
    required this.onProfile,
  });
  final String name;
  final String? avatarUrl;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFEFF3FF),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfile,
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  (avatarUrl != null && avatarUrl!.isNotEmpty) ? NetworkImage(avatarUrl!) : null,
              child: (avatarUrl == null || avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 32, color: Colors.black87)
                  : null,
            ),
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
                  const TextSpan(text: 'Welcome back,\n'),
                  TextSpan(
                    text: name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

/* --------------- CALORIES RING --------------- */
class _CaloriesRing extends StatelessWidget {
  const _CaloriesRing({
    required this.percent,
    required this.consumed,
    required this.goal,
  });
  final double percent;
  final double consumed;
  final double goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 52,
            lineWidth: 10,
            percent: percent,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            progressColor: theme.colorScheme.primary,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  consumed.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const Text('kcal', style: TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Calories',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700, color: Colors.black),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: percent,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 6),
                Text(
                  '${consumed.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} kcal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------- MACRO CARD --------------- */
class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  final String label;
  final double value;
  final double goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double pct = goal > 0 ? (value / goal).clamp(0.0, 1.0).toDouble() : 0.0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(0)}g',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: color.darken(),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Goal ${goal.toStringAsFixed(0)}g',
            style: TextStyle(fontSize: 11, color: color.darken(0.3)),
          ),
        ],
      ),
    );
  }
}

/* --------------- QUICK ACTIONS --------------- */
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onWorkouts,
    required this.onNutrition,
    required this.onProgress,
    required this.onChat,
  });
  final VoidCallback onWorkouts;
  final VoidCallback onNutrition;
  final VoidCallback onProgress;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final items = [
      _QA(icon: Icons.fitness_center, label: 'Workouts', onTap: onWorkouts, color: Colors.deepPurple),
      _QA(icon: Icons.restaurant, label: 'Meals', onTap: onNutrition, color: Colors.orange),
      _QA(icon: Icons.show_chart, label: 'Progress', onTap: onProgress, color: Colors.green),
      _QA(icon: Icons.forum_outlined, label: 'Chat', onTap: onChat, color: Colors.indigo),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: .78,
      ),
      itemBuilder: (_, i) => items[i],
    );
  }
}

class _QA extends StatelessWidget {
  const _QA({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/* --------------- SECTION HEADER --------------- */
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

/* --------------- ACTIVITY TILE --------------- */
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(.3)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(.15),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
          subtitle: Text(subtitle, style: const TextStyle(color: Colors.black54)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ),
    );
  }
}

/* --------------- LOADING PLACEHOLDERS --------------- */
class _LoadingRow extends StatelessWidget {
  const _LoadingRow();
  @override
  Widget build(BuildContext context) {
    Widget box() => Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(18),
          ),
        );
    return Column(
      children: [
        Container(
          height: 130,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: box()),
            const SizedBox(width: 10),
            Expanded(child: box()),
            const SizedBox(width: 10),
            Expanded(child: box()),
          ],
        ),
      ],
    );
  }
}

/* --------------- COLOR EXTENSION --------------- */
extension _ColorX on Color {
  Color darken([double amount = 0.15]) {
    final hsl = HSLColor.fromColor(this);
    final d = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(d).toColor();
  }
}

/* --------------- NUTRITION GOAL ACCESSORS --------------- */
extension NutritionGoalAccessors on NutritionGoal {
  double get calories {
    try {
      final d = (this as dynamic);
      final candidates = [d.calories, d.calorieGoal, d.goalCalories, d.dailyCalories, d.targetCalories];
      for (final c in candidates) {
        if (c is num) return c.toDouble();
      }
    } catch (_) {}
    return 0;
  }

  double get protein {
    try {
      final d = (this as dynamic);
      final candidates = [d.protein, d.proteinGoal, d.goalProtein, d.dailyProtein, d.targetProtein];
      for (final c in candidates) {
        if (c is num) return c.toDouble();
      }
    } catch (_) {}
    return 0;
  }

  double get carbs {
    try {
      final d = (this as dynamic);
      final candidates = [d.carbs, d.carbGoal, d.goalCarbs, d.dailyCarbs, d.targetCarbs];
      for (final c in candidates) {
        if (c is num) return c.toDouble();
      }
    } catch (_) {}
    return 0;
  }

  double get fats {
    try {
      final d = (this as dynamic);
      final candidates = [
        d.fats,
        d.fat,
        d.fatGoal,
        d.goalFats,
        d.goalFat,
        d.dailyFats,
        d.dailyFat,
        d.targetFats
      ];
      for (final c in candidates) {
        if (c is num) return c.toDouble();
      }
    } catch (_) {}
    return 0;
  }
}

/* --------------- STRING EXTENSION --------------- */
extension _Cap on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

/* --------------- FORM CHECK SHORTCUT CARD --------------- */
class _FormCheckShortcutCard extends StatelessWidget {
  const _FormCheckShortcutCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 70,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.videocam, size: 38, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Form Check\nRecord or review your exercise form.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
