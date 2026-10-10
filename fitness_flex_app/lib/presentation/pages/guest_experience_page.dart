import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_flex_app/core/themes/app_theme.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';

/// A fully local preview. No Firebase Auth, Firestore or backend calls.
/// Demo progress belongs only to this browser/device and is not transferred
/// to an account after sign-in.
class GuestExperiencePage extends StatefulWidget {
  const GuestExperiencePage({super.key});
  @override
  State<GuestExperiencePage> createState() => _GuestExperiencePageState();
}

class _Exercise {
  const _Exercise(this.name, this.group, this.description, this.difficulty, this.reps, this.icon);
  final String name, group, description, difficulty, reps;
  final IconData icon;
}

const _exercises = <_Exercise>[
  _Exercise('Back squat', 'Lower body', 'Sit down between your hips and stand tall. Keep the movement controlled.', 'Intermediate', '3 sets · 8 reps', Icons.accessibility_new_rounded),
  _Exercise('Bodyweight squat', 'Lower body', 'Practice an even descent and a comfortable range of motion.', 'Beginner', '3 sets · 12 reps', Icons.directions_walk_rounded),
  _Exercise('Push-up', 'Upper body', 'Keep a long body line. Lower and press with control.', 'Beginner', '3 sets · 10 reps', Icons.fitness_center_rounded),
  _Exercise('Reverse lunge', 'Lower body', 'Step back and lower gently; alternate legs.', 'Beginner', '3 sets · 10 / side', Icons.hiking_rounded),
  _Exercise('Plank', 'Core', 'Hold a steady position while breathing normally.', 'Beginner', '3 sets · 30 sec', Icons.self_improvement_rounded),
  _Exercise('Glute bridge', 'Lower body', 'Lift the hips without arching the lower back.', 'Beginner', '3 sets · 12 reps', Icons.landscape_rounded),
  _Exercise('Bent-over row', 'Upper body', 'Brace and pull the weight toward the hip.', 'Intermediate', '3 sets · 10 reps', Icons.sports_gymnastics_rounded),
  _Exercise('Dead bug', 'Core', 'Alternate opposite arm and leg with slow movements.', 'Beginner', '3 sets · 8 / side', Icons.spa_rounded),
];

class _GuestExperiencePageState extends State<GuestExperiencePage> {
  static const _dateKey = 'ff_guest_date_v1';
  static const _doneKey = 'ff_guest_completed_v1';
  static const _waterKey = 'ff_guest_water_v1';
  int _selected = 0;
  int _completed = 0;
  int _water = 0;
  bool _ready = false;
  SharedPreferences? _storage;

  String get _today {
    final now = DateTime.now();
    return now.year.toString() + '-' +
        now.month.toString().padLeft(2, '0') + '-' +
        now.day.toString().padLeft(2, '0');
  }

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_dateKey) != _today) {
        await prefs.setString(_dateKey, _today);
        await prefs.setInt(_doneKey, 0);
        await prefs.setInt(_waterKey, 0);
      }
      if (!mounted) return;
      setState(() {
        _storage = prefs;
        _completed = prefs.getInt(_doneKey) ?? 0;
        _water = prefs.getInt(_waterKey) ?? 0;
        _ready = true;
      });
    } catch (_) {
      // Storage may be unavailable in private browsing. Guest mode still works
      // in memory; the interface never promises persistence when unavailable.
      if (mounted) setState(() => _ready = true);
    }
  }

  Future<void> _finishExercise() async {
    setState(() => _completed += 1);
    await _storage?.setInt(_doneKey, _completed);
  }

  Future<void> _addWater() async {
    setState(() => _water += 1);
    await _storage?.setInt(_waterKey, _water);
  }

  void _showExercise(_Exercise entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(entry.group.toUpperCase(),
                style: const TextStyle(color: AppTheme.greyColor,
                  fontFamily: 'monospace', letterSpacing: 1)),
              const SizedBox(height: 12),
              Text(entry.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(entry.description),
              const SizedBox(height: 18),
              _infoPill(entry.reps),
              const SizedBox(height: 26),
              FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark exercise completed'),
                onPressed: () async {
                  await _finishExercise();
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved to your local guest session')),
                  );
                },
              ),
            ]),
        ),
      ),
    );
  }

  Widget _infoPill(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.secondaryColor.withOpacity(.35),
      borderRadius: BorderRadius.circular(13)),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  Widget _panel({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderColor)),
      child: child,
    );
  }

  Widget _stat(String label, String value, IconData icon) => Expanded(
    child: _panel(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppTheme.accentColor),
        const SizedBox(height: 13),
        Text(value, style: const TextStyle(
          fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: -1)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(
          fontSize: 11, color: AppTheme.greyColor)),
      ],
    )),
  );

  Widget _banner() => Container(
    padding: const EdgeInsets.all(23),
    decoration: BoxDecoration(color: AppTheme.darkSurface,
      borderRadius: BorderRadius.circular(24)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('FITNESSFLEX / GUEST MODE',
        style: TextStyle(color: AppTheme.secondaryColor,
          fontSize: 10, fontFamily: 'monospace', letterSpacing: 1.4)),
      const SizedBox(height: 14),
      const Text('Train your way.', style: TextStyle(
        color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900,
        letterSpacing: -1)),
      const SizedBox(height: 10),
      const Text('Explore exercises, log demo activity and try our motion research tools.',
        style: TextStyle(color: Color(0xFFCED8D5), height: 1.5)),
      const SizedBox(height: 18),
      Text('Guest data stays on this device. No account or cloud backup.',
        style: TextStyle(color: AppTheme.secondaryColor.withOpacity(.9), fontSize: 12)),
    ]),
  );

  Widget _home() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _banner(),
    const SizedBox(height: 18),
    Row(children: [
      _stat('Completed today', _completed.toString(), Icons.check_circle_outline),
      const SizedBox(width: 12),
      _stat('Water glasses', _water.toString(), Icons.water_drop_outlined),
    ]),
    const SizedBox(height: 22),
    const Text('Explore FitnessFlex',
      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
    const SizedBox(height: 12),
    _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Movement intelligence',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 9),
      const Text('Explore squat technique, movement replay and experimental research.'),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: () => Navigator.pushNamed(context, AppRouter.formCheckMenu),
        icon: const Icon(Icons.accessibility_new),
        label: const Text('Explore form check'),
      ),
    ])),
    const SizedBox(height: 12),
    OutlinedButton.icon(
      onPressed: () => setState(() => _selected = 1),
      icon: const Icon(Icons.fitness_center),
      label: const Text('Browse exercises'),
    ),
  ]);

  Widget _workouts() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Exercise library',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
      const SizedBox(height: 7),
      const Text('Try a suggested routine. These are examples, not personalised programmes.',
        style: TextStyle(color: AppTheme.greyColor)),
      const SizedBox(height: 18),
      for (final entry in _exercises) Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _panel(padding: const EdgeInsets.fromLTRB(15, 13, 11, 13),
          child: InkWell(
            onTap: () => _showExercise(entry),
            borderRadius: BorderRadius.circular(14),
            child: Row(children: [
              Container(width: 46, height: 46,
                decoration: BoxDecoration(color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(13)),
                child: Icon(entry.icon, color: AppTheme.primaryColor)),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(entry.group + ' · ' + entry.reps,
                  style: const TextStyle(fontSize: 11, color: AppTheme.greyColor)),
              ])),
              const Icon(Icons.chevron_right),
            ]),
          )),
      ),
    ],
  );

  Widget _hydration() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('Hydration tracker',
      style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
    const SizedBox(height: 6),
    const Text('Quick practice logging. No data is uploaded to Firebase.',
      style: TextStyle(color: AppTheme.greyColor)),
    const SizedBox(height: 22),
    _panel(child: Column(children: [
      const Icon(Icons.water_drop, size: 52, color: AppTheme.accentColor),
      const SizedBox(height: 12),
      Text(_water.toString() + ' glasses', style: const TextStyle(
        fontSize: 34, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      const Text('Logged today · demo session'),
      const SizedBox(height: 22),
      FilledButton.icon(onPressed: _addWater,
        icon: const Icon(Icons.add),
        label: const Text('Add a glass')),
    ])),
    const SizedBox(height: 12),
    const Text('Drink based on your needs. This is not a hydration prescription.',
      style: TextStyle(color: AppTheme.greyColor, fontSize: 12)),
  ]);

  Widget _progress() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('Today’s progress',
      style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
    const SizedBox(height: 10),
    _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Exercise sessions completed: ' + _completed.toString(),
        style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      LinearProgressIndicator(value: (_completed / 4).clamp(0.0, 1.0),
        minHeight: 10, borderRadius: BorderRadius.circular(8)),
      const SizedBox(height: 21),
      Text('Glasses logged: ' + _water.toString(),
        style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      LinearProgressIndicator(value: (_water / 8).clamp(0.0, 1.0),
        minHeight: 10, borderRadius: BorderRadius.circular(8)),
    ])),
    const SizedBox(height: 18),
    _panel(child: const Text(
      'These counters are local examples, not real workout measurements or medical goals. '
      'Create an account to use the full saved workout and nutrition features.',
      style: TextStyle(height: 1.55))),
    const SizedBox(height: 14),
    OutlinedButton.icon(
      onPressed: () => Navigator.pushNamed(context, AppRouter.login),
      icon: const Icon(Icons.login),
      label: const Text('Sign in to FitnessFlex')),
  ]);

  @override
  Widget build(BuildContext context) {
    final body = !_ready
        ? const Center(child: CircularProgressIndicator())
        : switch (_selected) {
            1 => _workouts(),
            2 => _hydration(),
            3 => _progress(),
            _ => _home(),
          };
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitnessFlex'),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Center(child: Text('GUEST', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.greyColor))),
          ),
          TextButton(onPressed: () => Navigator.pushNamed(context, AppRouter.login),
            child: const Text('Sign in')),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 950),
        child: ListView(
          key: ValueKey('guest-tab-' + _selected.toString()),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [body],
        ),
      ))),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected,
        onDestinationSelected: (i) => setState(() => _selected = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center), label: 'Exercises'),
          NavigationDestination(icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop), label: 'Hydration'),
          NavigationDestination(icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights), label: 'Progress'),
        ],
      ),
    );
  }
}
