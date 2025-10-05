import 'package:flutter/material.dart';
import 'package:fitness_flex_app/core/themes/app_theme.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';
import 'package:fitness_flex_app/data/repositories/nutrition_repository.dart';
import 'package:fitness_flex_app/data/models/nutrition_goal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final NutritionRepository _nutritionRepository = NutritionRepository();

  late Future<Map<String, double>> _todaySummaryF;
  late Future<NutritionGoal> _goalF;

  late Future<List<int>> _weeklyWorkoutMinsF;
  late Future<List<Map<String, double>>> _weeklyCaloriesInOutF;
  late Future<Map<String, double>> _todayActivityProgressF; // steps/hydration

  // Range: 0 = Day, 1 = Week
  int _rangeIndex = 1;

  // Today-only futures (hourly)
  late Future<List<double>> _todayWorkoutMinsHourlyF;
  late Future<List<Map<String, double>>> _todayCaloriesHourlyF;

  int _selectedIndex = 3; // Progress tab

  // Firestore collection names (change if your schema differs)
  static const String _colWorkouts = 'workout_logs';
  static const String _colNutrition = 'meals';
  static const String _colSteps = 'steps_logs';
  static const String _colHydration = 'hydration_logs';

  // Scroll controllers for bidirectional chart scrolling
  late final ScrollController _workoutHCtrl;
  late final ScrollController _workoutVCtrl;
  late final ScrollController _calHCtrl;
  late final ScrollController _calVCtrl;
  // NEW: weekly chart controllers
  late final ScrollController _weeklyWorkoutHCtrl;
  late final ScrollController _weeklyWorkoutVCtrl;
  late final ScrollController _weeklyCalHCtrl;
  late final ScrollController _weeklyCalVCtrl;

  @override
  void initState() {
    super.initState();
    _workoutHCtrl = ScrollController();
    _workoutVCtrl = ScrollController();
    _calHCtrl = ScrollController();
    _calVCtrl = ScrollController();
    // init weekly controllers
    _weeklyWorkoutHCtrl = ScrollController();
    _weeklyWorkoutVCtrl = ScrollController();
    _weeklyCalHCtrl = ScrollController();
    _weeklyCalVCtrl = ScrollController();
    _reloadAll();
  }

  @override
  void dispose() {
    _workoutHCtrl.dispose();
    _workoutVCtrl.dispose();
    _calHCtrl.dispose();
    _calVCtrl.dispose();
    _weeklyWorkoutHCtrl.dispose();
    _weeklyWorkoutVCtrl.dispose();
    _weeklyCalHCtrl.dispose();
    _weeklyCalVCtrl.dispose();
    super.dispose();
  }

  void _reloadAll() {
    _todaySummaryF = _nutritionRepository.getTodayNutritionSummary();
    _goalF = _nutritionRepository.getNutritionGoal();
    _weeklyWorkoutMinsF = _fetchWeeklyWorkoutMins();
    _weeklyCaloriesInOutF = _fetchWeeklyCaloriesInOut();
    _todayActivityProgressF = _fetchTodayActivityProgress();
    // today
    _todayWorkoutMinsHourlyF = _fetchTodayWorkoutMinsHourly();
    _todayCaloriesHourlyF = _fetchTodayCaloriesInOutHourly();
    setState(() {});
  }

  void _refresh() => _reloadAll();

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    switch (index) {
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
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Progress'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // HERO HEADER (KPIs)
            FutureBuilder<List<dynamic>>(
              future: Future.wait([
                _todayWorkoutMinsHourlyF,
                _todayCaloriesHourlyF,
              ]),
              builder: (context, snap) {
                final loading = snap.connectionState != ConnectionState.done;
                final workoutHourly = !loading && snap.hasData
                    ? (snap.data![0] as List<double>)
                    : List<double>.filled(24, 0);
                final calHourly = !loading && snap.hasData
                    ? (snap.data![1] as List<Map<String, double>>)
                    : List.generate(24, (_) => {'in': 0.0, 'out': 0.0});

                final minsToday = workoutHourly.fold<double>(
                  0,
                  (a, b) => a + b,
                );
                final inToday = calHourly.fold<double>(
                  0,
                  (a, m) => a + (m['in'] ?? 0),
                );
                final outToday = calHourly.fold<double>(
                  0,
                  (a, m) => a + (m['out'] ?? 0),
                );
                final balance = (inToday - outToday).round();

                return _heroHeader(
                  dateStr: dateStr,
                  loading: loading,
                  kpis: [
                    _KpiData(
                      label: "Calories In",
                      value: "${inToday.round()}",
                      color: Colors.orange,
                      icon: Icons.restaurant,
                    ),
                    _KpiData(
                      label: "Calories Out",
                      value: "${outToday.round()}",
                      color: Colors.green,
                      icon: Icons.local_fire_department,
                    ),
                    _KpiData(
                      label: "Workout Min",
                      value: "${minsToday.round()}",
                      color: AppTheme.primaryColor,
                      icon: Icons.fitness_center,
                    ),
                  ],
                  badge: balance == 0
                      ? "On Track"
                      : (balance > 0 ? "+$balance kcal" : "$balance kcal"),
                );
              },
            ),
            const SizedBox(height: 12),

            // Motivation banner (top)
            FutureBuilder<List<dynamic>>(
              future: Future.wait([
                _todaySummaryF,
                _goalF,
                _weeklyWorkoutMinsF,
              ]),
              builder: (context, snap) {
                final loading = snap.connectionState != ConnectionState.done;
                if (loading) return _loadingBox(height: 96);
                final Map<String, double> summary =
                    snap.data![0] as Map<String, double>;
                final NutritionGoal? goal = snap.data![1] as NutritionGoal?;
                final List<int> weeklyMins = snap.data![2] as List<int>;
                final msgs = _buildMotivationMessages(
                  summary,
                  goal,
                  weeklyMins,
                );
                return _motivationBanner(messages: msgs);
              },
            ),
            const SizedBox(height: 12),

            // Segmented toggle (Day / 7 Days)
            _buildRangeToggle(),

            const SizedBox(height: 12),

            // Charts: Day -> hourly; Week -> weekly
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _rangeIndex == 0
                  ? Column(
                      key: const ValueKey('day'),
                      children: [
                        FutureBuilder<List<double>>(
                          future: _todayWorkoutMinsHourlyF,
                          builder: (context, snap) {
                            final loading =
                                snap.connectionState != ConnectionState.done;
                            final data = !loading && snap.hasData
                                ? snap.data!
                                : List<double>.filled(24, 0.0);
                            return _sectionCard(
                              title: 'Workout Minutes (today)',
                              icon: Icons.fitness_center,
                              child: loading
                                  ? _loadingBox()
                                  : _buildWorkoutLineChartHourly(data),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<List<Map<String, double>>>(
                          future: _todayCaloriesHourlyF,
                          builder: (context, snap) {
                            final loading =
                                snap.connectionState != ConnectionState.done;
                            final data = !loading && snap.hasData
                                ? snap.data!
                                : List.generate(
                                    24,
                                    (_) => {'in': 0.0, 'out': 0.0},
                                  );
                            return _sectionCard(
                              title: 'Calories In vs Out (today)',
                              icon: Icons.local_fire_department,
                              child: loading
                                  ? _loadingBox()
                                  : _buildCaloriesBarChartHourlyBuckets(data),
                            );
                          },
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey('week'),
                      children: [
                        FutureBuilder<List<dynamic>>(
                          future: Future.wait([
                            _weeklyWorkoutMinsF,
                            _weeklyCaloriesInOutF,
                          ]),
                          builder: (context, snap) {
                            final loading =
                                snap.connectionState != ConnectionState.done;
                            final mins = !loading && snap.hasData
                                ? (snap.data![0] as List<int>)
                                : const <int>[];
                            final cal = !loading && snap.hasData
                                ? (snap.data![1] as List<Map<String, double>>)
                                : const <Map<String, double>>[];
                            return Column(
                              children: [
                                _sectionCard(
                                  title: 'Workout Minutes (7 days)',
                                  icon: Icons.timeline,
                                  child: loading
                                      ? _loadingBox()
                                      : _buildWorkoutLineChart(mins),
                                ),
                                const SizedBox(height: 12),
                                _sectionCard(
                                  title: 'Calories In vs Out (7 days)',
                                  icon: Icons.stacked_bar_chart,
                                  child: loading
                                      ? _loadingBox()
                                      : _buildCaloriesBarChart(cal),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 16),

            // Macros + Rings + Motivation
            FutureBuilder<List<dynamic>>(
              future: Future.wait([
                _todaySummaryF,
                _goalF,
                _weeklyWorkoutMinsF,
                _todayActivityProgressF,
              ]),
              builder: (context, snapshot) {
                final loading =
                    snapshot.connectionState != ConnectionState.done;
                final Map<String, double> summary = !loading && snapshot.hasData
                    ? snapshot.data![0] as Map<String, double>
                    : {};
                final NutritionGoal? goal = !loading && snapshot.hasData
                    ? snapshot.data![1] as NutritionGoal
                    : null;
                final List<int> weeklyMins = !loading && snapshot.hasData
                    ? snapshot.data![2] as List<int>
                    : const <int>[];
                final Map<String, double> act = !loading && snapshot.hasData
                    ? snapshot.data![3] as Map<String, double>
                    : const {'steps': 0.0, 'hydration': 0.0};

                return Column(
                  children: [
                    _sectionCard(
                      title: "Today's Macro Split",
                      icon: Icons.pie_chart,
                      child: loading
                          ? _loadingBox(height: 140)
                          : _buildMacroPieChart(summary),
                    ),
                    const SizedBox(height: 12),
                    _sectionCard(
                      title: 'Goal Completion',
                      icon: Icons.track_changes,
                      child: loading
                          ? _loadingBox(height: 120)
                          : _buildProgressRings(
                              workouts:
                                  weeklyMins.where((m) => m > 0).length / 5.0,
                              hydration: act['hydration'] ?? 0,
                              steps: act['steps'] ?? 0,
                              calories: _calcCalorieProgress(summary, goal),
                            ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  // ===== Firestore fetchers =====

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Small helpers to read flexible schemas
  Timestamp? _pickTs(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v is Timestamp) return v;
      if (v is DateTime) return Timestamp.fromDate(v);
      if (v is String) {
        try {
          return Timestamp.fromDate(DateTime.parse(v));
        } catch (_) {}
      }
    }
    return null;
  }

  double _pickNum(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v is num) return v.toDouble();
      if (v is String) {
        final p = double.tryParse(v);
        if (p != null) return p;
      }
    }
    return 0.0;
  }

  DateTime _startOfWeek(DateTime d) {
    final wd = d.weekday; // 1..7 Mon..Sun
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: wd - 1));
  }

  DateTime _endOfWeek(DateTime d) =>
      _startOfWeek(d).add(const Duration(days: 7));
  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) => _startOfDay(d).add(const Duration(days: 1));

  Future<List<int>> _fetchWeeklyWorkoutMins() async {
    if (_uid == null) return List<int>.filled(7, 0);
    final start = _startOfWeek(DateTime.now());
    final end = _endOfWeek(DateTime.now());
    final ref = _db
        .collection('users')
        .doc(_uid)
        .collection(_colWorkouts)
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('completedAt', isLessThan: Timestamp.fromDate(end));

    // If your docs use 'date' or 'timestamp' instead of 'completedAt', the fallback below still works.
    final snap = await ref.get();

    final res = List<int>.filled(7, 0);
    for (final doc in snap.docs) {
      final data = doc.data();
      final ts = _pickTs(data, ['completedAt', 'date', 'timestamp']);
      final mins = _pickNum(data, ['duration', 'durationMinutes']);
      if (ts == null) continue;
      final idx = ts.toDate().weekday - 1;
      if (idx >= 0 && idx < 7) res[idx] += mins.round();
    }
    return res;
  }

  Future<List<Map<String, double>>> _fetchWeeklyCaloriesInOut() async {
    if (_uid == null) return List.generate(7, (_) => {'in': 0.0, 'out': 0.0});
    final start = _startOfWeek(DateTime.now());
    final end = _endOfWeek(DateTime.now());

    // Meals (Calories IN)
    final mealsSnap = await _db
        .collection('users')
        .doc(_uid)
        .collection(_colNutrition)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .get();

    // Workouts (Calories OUT)
    final workoutsSnap = await _db
        .collection('users')
        .doc(_uid)
        .collection(_colWorkouts)
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('completedAt', isLessThan: Timestamp.fromDate(end))
        .get();

    final inArr = List<double>.filled(7, 0.0);
    final outArr = List<double>.filled(7, 0.0);

    for (final doc in mealsSnap.docs) {
      final data = doc.data();
      final ts = _pickTs(data, ['timestamp', 'date']);
      final calIn = _pickNum(data, ['calories', 'kcal', 'energy']);
      if (ts == null) continue;
      final idx = ts.toDate().weekday - 1;
      if (idx >= 0 && idx < 7) inArr[idx] += calIn;
    }

    for (final doc in workoutsSnap.docs) {
      final data = doc.data();
      final ts = _pickTs(data, ['completedAt', 'date', 'timestamp']);
      final calOut = _pickNum(data, ['calories', 'caloriesBurned']);
      if (ts == null) continue;
      final idx = ts.toDate().weekday - 1;
      if (idx >= 0 && idx < 7) outArr[idx] += calOut;
    }

    // Same-day fallback: if meals aren't persisted but NutritionRepository has data
    final todayIdx = DateTime.now().weekday - 1;
    final todaySummary = await _nutritionRepository.getTodayNutritionSummary();
    final todayIn = (todaySummary['calories'] ?? 0).toDouble();
    if (todayIn > 0 && inArr[todayIdx] == 0.0) {
      inArr[todayIdx] = todayIn;
    }

    return List.generate(7, (i) => {'in': inArr[i], 'out': outArr[i]});
  }

  Future<Map<String, double>> _fetchTodayActivityProgress() async {
    if (_uid == null) return {'steps': 0, 'hydration': 0};
    final user = await _db.collection('users').doc(_uid).get();
    final stepTarget =
        (user.data()?['dailyStepsTarget'] as num?)?.toDouble() ?? 10000;
    final waterTarget =
        (user.data()?['dailyWaterTargetMl'] as num?)?.toDouble() ?? 2000;

    final now = DateTime.now();
    final sSnap = await _db
        .collection('users')
        .doc(_uid)
        .collection(_colSteps)
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfDay(now)),
        )
        .where('date', isLessThan: Timestamp.fromDate(_endOfDay(now)))
        .get();

    final hSnap = await _db
        .collection('users')
        .doc(_uid)
        .collection(_colHydration)
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfDay(now)),
        )
        .where('date', isLessThan: Timestamp.fromDate(_endOfDay(now)))
        .get();

    final steps = sSnap.docs
        .fold<num>(0, (a, d) => a + ((d.data()['steps'] as num?) ?? 0))
        .toDouble();
    final water = hSnap.docs
        .fold<num>(0, (a, d) => a + ((d.data()['ml'] as num?) ?? 0))
        .toDouble();

    return {
      'steps': stepTarget > 0 ? (steps / stepTarget).clamp(0, 1).toDouble() : 0,
      'hydration': waterTarget > 0
          ? (water / waterTarget).clamp(0, 1).toDouble()
          : 0,
    };
  }

  // Today: workout minutes per hour (0..23)
  Future<List<double>> _fetchTodayWorkoutMinsHourly() async {
    if (_uid == null) return List<double>.filled(24, 0.0);
    final start = _startOfDay(DateTime.now());
    final end = _endOfDay(DateTime.now());
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection(_colWorkouts)
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('completedAt', isLessThan: Timestamp.fromDate(end))
        .get();

    final hourly = List<double>.filled(24, 0.0);
    for (final d in snap.docs) {
      final data = d.data();
      final ts = _pickTs(data, ['completedAt', 'date', 'timestamp']);
      final mins = _pickNum(data, ['duration', 'durationMinutes']);
      if (ts == null) continue;
      final h = ts.toDate().hour;
      if (h >= 0 && h < 24) hourly[h] += mins;
    }
    return hourly;
  }

  // Today: calories in/out per hour (0..23)
  Future<List<Map<String, double>>> _fetchTodayCaloriesInOutHourly() async {
    if (_uid == null) return List.generate(24, (_) => {'in': 0.0, 'out': 0.0});
    final start = _startOfDay(DateTime.now());
    final end = _endOfDay(DateTime.now());

    final mealsSnap = await _db
        .collection('users')
        .doc(_uid)
        .collection(_colNutrition)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .get();

    final workoutsSnap = await _db
        .collection('users')
        .doc(_uid)
        .collection(_colWorkouts)
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('completedAt', isLessThan: Timestamp.fromDate(end))
        .get();

    final hourly = List.generate(24, (_) => {'in': 0.0, 'out': 0.0});
    for (final d in mealsSnap.docs) {
      final data = d.data();
      final ts = _pickTs(data, ['timestamp', 'date', 'completedAt']);
      final cals = _pickNum(data, ['calories', 'kcal', 'energy']);
      if (ts == null) continue;
      final h = ts.toDate().hour;
      if (h >= 0 && h < 24) hourly[h]['in'] = (hourly[h]['in'] ?? 0.0) + cals;
    }
    for (final d in workoutsSnap.docs) {
      final data = d.data();
      final ts = _pickTs(data, ['completedAt', 'date', 'timestamp']);
      final cals = _pickNum(data, ['calories', 'caloriesBurned']);
      if (ts == null) continue;
      final h = ts.toDate().hour;
      if (h >= 0 && h < 24) hourly[h]['out'] = (hourly[h]['out'] ?? 0.0) + cals;
    }
    return hourly;
  }

  // ===== UI helpers =====

  double _calcCalorieProgress(
    Map<String, double> summary,
    NutritionGoal? goal,
  ) {
    if (goal == null || goal.dailyCalories <= 0) return 0;
    final cal = summary['calories'] ?? 0;
    return (cal / goal.dailyCalories).clamp(0, 1);
  }

  Widget _loadingBox({double height = 160}) => SizedBox(
    height: height,
    child: const Center(child: CircularProgressIndicator()),
  );

  Widget _buildCard(Widget child, {required String title}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  // Reusable scrollable chart wrapper
  Widget _scrollableChart({
    required double width,
    required double height,
    required Widget child,
    bool vertical = false,
  }) {
    // If you really want vertical scroll inside chart set vertical:true and adjust height.
    final scrollChild = SizedBox(width: width, height: height, child: child);
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
        child: vertical
            ? Column(children: [scrollChild])
            : Row(children: [scrollChild]),
      ),
    );
  }

  // Bidirectional scrollable chart wrapper (both scrollbars)
  Widget _biScrollableChart({
    required double contentWidth,
    required double contentHeight,
    required Widget child,
    required ScrollController hCtrl,
    required ScrollController vCtrl,
    double viewportHeight = 260,
  }) {
    return SizedBox(
      height: viewportHeight, // visible viewport
      child: Scrollbar(
        controller: vCtrl,
        thumbVisibility: true,
        notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
        child: SingleChildScrollView(
          controller: vCtrl,
          scrollDirection: Axis.vertical,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            height: contentHeight,
            child: Scrollbar(
              controller: hCtrl,
              thumbVisibility: true,
              notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: hCtrl,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: SizedBox(
                  width: contentWidth,
                  height: contentHeight,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Line: weekly workout minutes (NOW bidirectional)
  Widget _buildWorkoutLineChart(List<int> weeklyMins) {
    final spots = List.generate(
      7,
      (i) => FlSpot(
        i.toDouble(),
        (i < weeklyMins.length ? weeklyMins[i] : 0).toDouble(),
      ),
    );
    final chart = LineChart(
      LineChartData(
        minY: 0,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => _dayLabel(v.toInt()),
              interval: 1,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 48),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            spots: spots,
          ),
        ],
      ),
    );

    // Enlarge canvas so both scrollbars always appear
    const contentWidth = 7 * 160.0; // exaggerate width
    const contentHeight = 500.0; // extra height to allow vertical scroll

    return _biScrollableChart(
      contentWidth: contentWidth,
      contentHeight: contentHeight,
      child: chart,
      hCtrl: _weeklyWorkoutHCtrl,
      vCtrl: _weeklyWorkoutVCtrl,
      viewportHeight: 240,
    );
  }

  // Bar: calories in vs out (7 days) (NOW bidirectional)
  Widget _buildCaloriesBarChart(List<Map<String, double>> weekly) {
    final groups = List.generate(7, (i) {
      final inCal = i < weekly.length ? (weekly[i]['in'] ?? 0.0) : 0.0;
      final outCal = i < weekly.length ? (weekly[i]['out'] ?? 0.0) : 0.0;
      return BarChartGroupData(
        x: i,
        barsSpace: 14,
        barRods: [
          BarChartRodData(
            toY: inCal,
            color: Colors.orange,
            width: 22,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: outCal,
            color: Colors.green,
            width: 22,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    final chart = BarChart(
      BarChartData(
        barGroups: groups,
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => _dayLabel(v.toInt()),
              interval: 1,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 48),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );

    const contentWidth = 7 * 180.0;
    const contentHeight = 500.0;

    return Column(
      children: [
        _biScrollableChart(
          contentWidth: contentWidth,
          contentHeight: contentHeight,
          child: chart,
          hCtrl: _weeklyCalHCtrl,
          vCtrl: _weeklyCalVCtrl,
          viewportHeight: 240,
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: Colors.orange, label: 'In'),
            SizedBox(width: 12),
            _LegendDot(color: Colors.green, label: 'Out'),
          ],
        ),
      ],
    );
  }

  // Pie: macros split (today)
  Widget _buildMacroPieChart(Map<String, double> summary) {
    final p = (summary['protein'] ?? 0).toDouble();
    final c = (summary['carbs'] ?? 0).toDouble();
    final f = (summary['fat'] ?? 0).toDouble();
    final total = (p + c + f);
    if (total <= 0) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No macro data for today'),
      );
    }
    return SizedBox(
      height: 180,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 28,
          sections: [
            PieChartSectionData(
              value: p,
              color: Colors.red,
              title: 'P ${(p / total * 100).toStringAsFixed(0)}%',
              radius: 60,
              titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
            ),
            PieChartSectionData(
              value: c,
              color: Colors.green,
              title: 'C ${(c / total * 100).toStringAsFixed(0)}%',
              radius: 60,
              titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
            ),
            PieChartSectionData(
              value: f,
              color: Colors.blue,
              title: 'F ${(f / total * 100).toStringAsFixed(0)}%',
              radius: 60,
              titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // Progress rings
  Widget _buildProgressRings({
    required double workouts,
    required double hydration,
    required double steps,
    required double calories,
  }) {
    Widget ring(String label, double v, Color color) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularPercentIndicator(
            radius: 36,
            lineWidth: 8,
            percent: v.clamp(0, 1),
            progressColor: color,
            backgroundColor: color.withOpacity(0.15),
            center: Text('${(v * 100).round()}%'),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ring('Workouts', workouts, AppTheme.primaryColor),
        ring('Hydration', hydration, Colors.cyan),
        ring('Steps', steps, Colors.teal),
        ring('Calories', calories, Colors.orange),
      ],
    );
  }

  // Stats and streaks (from weekly workouts)
  Widget _buildStatsAndStreaks(List<int> weeklyMins) {
    final totalSessions = weeklyMins.where((m) => m > 0).length;
    final totalMinutes = weeklyMins.fold<int>(0, (a, b) => a + b);
    const strongestLift = '—'; // wire specific PRs if you store them
    const longestRun = '—';

    Widget statCard(IconData icon, String title, String value, Color color) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stats & Summaries',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.7,
          children: [
            statCard(
              Icons.event_available,
              'Total Sessions',
              '$totalSessions',
              AppTheme.primaryColor,
            ),
            statCard(
              Icons.schedule,
              'Total Minutes',
              '$totalMinutes min',
              Colors.indigo,
            ),
            statCard(
              Icons.fitness_center,
              'Strongest Lift',
              strongestLift,
              Colors.red,
            ),
            statCard(
              Icons.directions_run,
              'Longest Run',
              longestRun,
              Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  // Milestones (static demo; wire to your achievements collection if present)
  Widget _buildMilestones() {
    final items = [
      {
        'icon': Icons.emoji_events,
        'title': '10 Workouts',
        'color': Colors.amber,
      },
      {
        'icon': Icons.calendar_month,
        'title': '1 Month Streak',
        'color': Colors.purple,
      },
      {
        'icon': Icons.directions_run,
        'title': '100 km Run',
        'color': Colors.green,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Milestones & Achievements',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final it = items[i];
              return Container(
                width: 180,
                decoration: BoxDecoration(
                  color: (it['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (it['color'] as Color).withOpacity(0.25),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: (it['color'] as Color).withOpacity(0.2),
                      child: Icon(
                        it['icon'] as IconData,
                        color: it['color'] as Color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        it['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Motivation & guidance
  Widget _buildMotivationBlock(
    Map<String, double> summary,
    NutritionGoal? goal,
    List<int> weeklyMins,
  ) {
    final calories = summary['calories'] ?? 0;
    final protein = summary['protein'] ?? 0;
    final needProtein = goal != null && protein < goal.dailyProtein * 0.8;

    final msg = <String>[
      if (goal != null)
        "You’re ${(calories / (goal.dailyCalories == 0 ? 1 : goal.dailyCalories) * 100).clamp(0, 100).toStringAsFixed(0)}% toward today’s calories goal — keep going!",
      "Just ${weeklyMins.where((m) => m > 0).length >= 3 ? 2 : 1} workouts away from your next badge.",
      if (needProtein)
        "Protein looks low today — consider a lean protein meal.",
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Motivation & Tips',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...msg.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(m)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Day labels
  Widget _dayLabel(int i) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    if (i < 0 || i >= days.length) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(days[i], style: const TextStyle(fontSize: 10)),
    );
  }

  // Hourly labels
  Widget _hourLabel(int h) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(h.toString().padLeft(2, '0')),
  );
  Widget _bucketLabel(int i) {
    const ranges = ['0-3', '4-7', '8-11', '12-15', '16-19', '20-23'];
    final txt = (i >= 0 && i < ranges.length) ? ranges[i] : '';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(txt, style: const TextStyle(fontSize: 10)),
    );
  }

  // Line: workout minutes (hourly)
  Widget _buildWorkoutLineChartHourly(List<double> hourlyMins) {
    final spots = List.generate(24, (i) => FlSpot(i.toDouble(), hourlyMins[i]));
    final chart = LineChart(
      LineChartData(
        minY: 0,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, _) => _hourLabel(v.toInt()),
              reservedSize: 32,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 56),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            spots: spots,
          ),
        ],
      ),
    );

    // Content size (bigger than viewport so scrollbars appear)
    const contentWidth = 24 * 70.0; // you can tweak (hour * px)
    const contentHeight =
        520.0; // extra vertical space so vertical scroll is meaningful

    return _biScrollableChart(
      contentWidth: contentWidth,
      contentHeight: contentHeight,
      child: chart,
      hCtrl: _workoutHCtrl,
      vCtrl: _workoutVCtrl,
      viewportHeight: 260,
    );
  }

  // Bar: calories in vs out (hourly buckets)
  Widget _buildCaloriesBarChartHourlyBuckets(List<Map<String, double>> hourly) {
    final buckets = List.generate(6, (_) => {'in': 0.0, 'out': 0.0});
    for (var h = 0; h < 24; h++) {
      final b = h ~/ 4;
      buckets[b]['in'] = (buckets[b]['in'] ?? 0) + (hourly[h]['in'] ?? 0);
      buckets[b]['out'] = (buckets[b]['out'] ?? 0) + (hourly[h]['out'] ?? 0);
    }

    final groups = List.generate(6, (i) {
      final inCal = (buckets[i]['in'] ?? 0).toDouble();
      final outCal = (buckets[i]['out'] ?? 0).toDouble();
      return BarChartGroupData(
        x: i,
        barsSpace: 12,
        barRods: [
          BarChartRodData(
            toY: inCal,
            color: Colors.orange,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: outCal,
            color: Colors.green,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    final chart = BarChart(
      BarChartData(
        barGroups: groups,
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => _bucketLabel(v.toInt()),
              interval: 1,
              reservedSize: 40,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 56),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );

    const contentWidth = 6 * 160.0; // widen each bucket zone
    const contentHeight = 500.0; // vertical scroll area

    return Column(
      children: [
        _biScrollableChart(
          contentWidth: contentWidth,
          contentHeight: contentHeight,
          child: chart,
          hCtrl: _calHCtrl,
          vCtrl: _calVCtrl,
          viewportHeight: 260,
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: Colors.orange, label: 'In'),
            SizedBox(width: 12),
            _LegendDot(color: Colors.green, label: 'Out'),
          ],
        ),
      ],
    );
  }

  // ---------- Styled widgets ----------

  Widget _heroHeader({
    required String dateStr,
    required List<_KpiData> kpis,
    required bool loading,
    required String badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                dateStr,
                style: TextStyle(color: Colors.white.withOpacity(0.9)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const SizedBox(
              height: 52,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            Row(
              children: [
                for (final k in kpis) Expanded(child: _KpiChip(data: k)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRangeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white, // white toggle background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _segBtn(label: 'Day', index: 0),
          _segBtn(label: '7 Days', index: 1),
        ],
      ),
    );
  }

  Expanded _segBtn({required String label, required int index}) {
    final selected = _rangeIndex == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _rangeIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white, // white buttons
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppTheme.primaryColor : Colors.black12,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected
                  ? AppTheme.primaryColor
                  : Colors.black87, // readable text
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _motivationBanner({required List<String> messages}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Motivation',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...messages
              .take(3)
              .map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  List<String> _buildMotivationMessages(
    Map<String, double> summary,
    NutritionGoal? goal,
    List<int> weeklyMins,
  ) {
    final calories = summary['calories'] ?? 0;
    final protein = summary['protein'] ?? 0;
    final dailyCalTarget = goal?.dailyCalories ?? 0;
    final pct = dailyCalTarget > 0
        ? ((calories / dailyCalTarget) * 100).clamp(0, 999).toStringAsFixed(0)
        : '—';
    final needProtein =
        goal != null &&
        goal.dailyProtein > 0 &&
        protein < goal.dailyProtein * 0.8;
    final sessions = weeklyMins.where((m) => m > 0).length;
    final minsTotal = weeklyMins.fold<int>(0, (a, b) => a + b);

    return [
      if (dailyCalTarget > 0)
        'You are $pct% toward today’s calorie goal — nice pace!',
      if (minsTotal > 0)
        'Great work: $minsTotal min this week • $sessions sessions logged.',
      if (needProtein)
        'Protein is a bit low — add a lean protein to your next meal.',
      if (dailyCalTarget == 0 && calories > 0)
        'Calories logged today: ${calories.toStringAsFixed(0)} kcal — keep it up!',
    ];
  }
}

// Small KPI chip
class _KpiData {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  _KpiData({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
}

class _KpiChip extends StatelessWidget {
  final _KpiData data;
  const _KpiChip({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, // solid white for readability
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, color: data.color, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
              Text(
                data.value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ), // force dark text
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
