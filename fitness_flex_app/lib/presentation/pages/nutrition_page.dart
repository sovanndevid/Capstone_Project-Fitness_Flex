import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/repositories/nutrition_repository.dart';
import 'package:fitness_flex_app/presentation/pages/meal_log_page.dart';
import 'package:fitness_flex_app/presentation/pages/water_tracker_page.dart';
import 'package:fitness_flex_app/presentation/pages/nutrition_goals_page.dart';
import 'package:fitness_flex_app/presentation/pages/meal_history_page.dart';
import 'package:fitness_flex_app/data/models/meal.dart';
import 'package:fitness_flex_app/data/models/nutrition_goal.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';
import 'package:fitness_flex_app/core/themes/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final NutritionRepository _nutritionRepository = NutritionRepository();
  late Future<Map<String, double>> _nutritionSummaryFuture;
  late Future<double> _waterSummaryFuture;
  late Future<NutritionGoal> _nutritionGoalFuture;

  static const _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
  String _selectedMealType = 'breakfast';
  int _selectedIndex = 2;

  final PageController _pageController = PageController();
  int _current = 0;

  final List<Map<String, String>> _slides = const [
    {
      'image': 'assets/images/nutrition.jpg',
      'quote': 'Fuel smart. Perform strong.',
    },
    {
      'image': 'assets/images/nutrition2.jpg',
      'quote': 'Hydrate early. Sustain energy.',
    },
    {
      'image': 'assets/images/nutrition3.jpg',
      'quote': 'Eat color. Unlock nutrients.',
    },
    {
      'image': 'assets/images/nutrition4.jpg',
      'quote': 'Consistency compounds results.',
    },
  ];

  Timer? _heroTimer;
  double _scrollOffset = 0;

  final GlobalKey _mealListSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadData();
    _precacheHeroImages();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _loadData() {
    _nutritionSummaryFuture = _nutritionRepository.getTodayNutritionSummary();
    _waterSummaryFuture = _nutritionRepository.getTodayWaterSummary();
    _nutritionGoalFuture = _nutritionRepository.getNutritionGoal();
  }

  void _refreshData() {
    setState(() {
      _loadData();
    });
  }

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
        // already here
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRouter.progress);
        break;
    }
  }

  void _startAutoPlay() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (!_pageController.hasClients) return;
      final next = (_current + 1) % _slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _precacheHeroImages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final s in _slides) {
        precacheImage(AssetImage(s['image']!), context);
      }
    });
  }

  // Helper to get bounded percentage as double
  double _pct(double value, double goal) {
    if (goal <= 0) return 0.0;
    final p = value / goal;
    if (p < 0) return 0.0;
    if (p > 1) return 1.0;
    return p.toDouble();
  }

  // Fixed: removed invalid use of keyword 'try' as function name
  Future<void> _quickAddWater(double liters) async {
    final repo = _nutritionRepository as dynamic;
    bool succeeded = false;

    Future<bool> attempt(Future<dynamic> Function() fn) async {
      try {
        await fn();
        return true;
      } catch (_) {
        return false;
      }
    }

    if (await attempt(() async => await repo.addWater(liters))) {
      succeeded = true;
    } else if (await attempt(() async => await repo.addWaterIntake(liters))) {
      succeeded = true;
    } else if (await attempt(() async => await repo.logWater(liters))) {
      succeeded = true;
    } else if (await attempt(() async => await repo.recordWater(liters))) {
      succeeded = true;
    } else if (await attempt(() async => await repo.saveWater(liters))) {
      succeeded = true;
    }

    if (succeeded) {
      _refreshData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('+${(liters * 1000).toInt()} ml added')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quick add not supported by repository'),
          ),
        );
      }
    }
  }

  Widget _buildHeroSlider() {
    const double outerRadius = 34;
    final collapseT = (_scrollOffset / 140).clamp(0.0, 1.0).toDouble();
    final scale = (1 - _scrollOffset.abs() / 140 * 0.06)
        .clamp(.94, 1.0)
        .toDouble();
    final opacity = (1 - (collapseT * 0.55)).clamp(0.0, 1.0).toDouble();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              SizedBox(
                height: 240,
                child: AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, _) {
                    final pct = (_current + 1) / _slides.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(outerRadius),
                        color: Colors.white.withOpacity(.06),
                        border: Border.all(
                          color: Colors.white.withOpacity(.85),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.12),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(.35),
                            blurRadius: 26,
                            spreadRadius: -6,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(outerRadius - 2),
                          color: Colors.white.withOpacity(.05),
                          border: Border.all(
                            color: Colors.white.withOpacity(.20),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(outerRadius - 6),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: _slides.length,
                                allowImplicitScrolling: true,
                                physics: const BouncingScrollPhysics(),
                                onPageChanged: (i) =>
                                    setState(() => _current = i),
                                itemBuilder: (context, index) {
                                  return _ParallaxHeroSlide(
                                    key: ValueKey(_slides[index]['image']),
                                    imagePath: _slides[index]['image']!,
                                    quote: _slides[index]['quote']!,
                                    index: index,
                                    controller: _pageController,
                                    active: index == _current,
                                  );
                                },
                              ),
                              Positioned(
                                top: -40,
                                left: -30,
                                child: IgnorePointer(
                                  child: AnimatedScale(
                                    scale: 0.9 + (pct * 0.2),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOut,
                                    child: Container(
                                      width: 180,
                                      height: 180,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            Color(0x66FFFFFF),
                                            Color(0x00FFFFFF),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              IgnorePointer(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0x00000000),
                                        Color(0x44000000),
                                        Color(0x88000000),
                                      ],
                                      stops: [0.0, .62, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 1.2,
                                      color: Colors.white.withOpacity(.18),
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      outerRadius - 6,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 360),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    height: 12,
                    width: active ? 34 : 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: active ? Colors.white : Colors.grey.shade400,
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: Icons.restaurant_menu_rounded,
              label: 'Add Meal',
              color: const Color(0xFF43A047),
              onTap: () => _navigateToMealLog(_selectedMealType),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.water_drop_rounded,
              label: 'Water +250ml',
              color: const Color(0xFF039BE5),
              onTap: () => _quickAddWater(0.25),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.flag_circle_rounded,
              label: 'Goals',
              color: const Color(0xFF8E24AA),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NutritionGoalsPage(
                      nutritionRepository: _nutritionRepository,
                      onGoalUpdated: _refreshData,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // light neutral background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(.9),
        surfaceTintColor: Colors.white,
        title: const Text('Nutrition', style: TextStyle(color: Colors.black87)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NutritionGoalsPage(
                    nutritionRepository: _nutritionRepository,
                    onGoalUpdated: _refreshData,
                  ),
                ),
              );
            },
            tooltip: 'Nutrition Goals',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FA), Color(0xFFEFF3F7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            _refreshData();
            return Future.delayed(const Duration(milliseconds: 500));
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.axis == Axis.vertical) {
                setState(() => _scrollOffset = n.metrics.pixels.clamp(0, 160));
              }
              return false;
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _buildHeroSlider()),
                SliverToBoxAdapter(child: _buildQuickActions()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _buildNutritionSummaryCard(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildWaterTrackingCard(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: _buildMealTypeSelector(),
                  ),
                ),
                SliverToBoxAdapter(
                  key: _mealListSectionKey,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey(_selectedMealType),
                        child: _buildRecentMealsList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
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
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    return _MealTypeSegmentedControl(
      mealTypes: _mealTypes,
      current: _selectedMealType,
      colorFor: _getMealTypeColor,
      onChanged: (t) {
        if (t != _selectedMealType) {
          setState(() => _selectedMealType = t);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = _mealListSectionKey.currentContext;
            if (ctx != null) {
              Scrollable.ensureVisible(
                ctx,
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                alignment: 0.05,
              );
            }
          });
        }
      },
      onLogMeal: (t) => _navigateToMealLog(t),
    );
  }

  Widget _buildMealSectionHeader() {
    final title =
        _selectedMealType[0].toUpperCase() + _selectedMealType.substring(1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$title Meals',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MealHistoryPage(
                  nutritionRepository: _nutritionRepository,
                  initialMealType: _selectedMealType, // renamed from mealType
                ),
              ),
            );
          },
          icon: const Icon(Icons.history_rounded, size: 18),
          label: const Text('History'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionSummaryCard() {
    return FutureBuilder<Map<String, double>>(
      future: _nutritionSummaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonCard(height: 200);
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorCard('Failed to load nutrition data');
        }

        final data = snapshot.data!;
        return FutureBuilder<NutritionGoal>(
          future: _nutritionGoalFuture,
          builder: (context, goalSnap) {
            final goal =
                goalSnap.data ??
                NutritionGoal(
                  dailyCalories: 2000,
                  dailyProtein: 150,
                  dailyCarbs: 250,
                  dailyFat: 70,
                  dailyWater: 2.5,
                );

            final calories = data['calories'] ?? 0;
            final protein = data['protein'] ?? 0;
            final carbs = data['carbs'] ?? 0;
            final fat = data['fat'] ?? 0;
            final caloriePct = _pct(calories, goal.dailyCalories);

            return _SectionCard(
              title: "Today's Nutrition",
              trailing: IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Adjust Goals',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NutritionGoalsPage(
                        nutritionRepository: _nutritionRepository,
                        onGoalUpdated: _refreshData,
                      ),
                    ),
                  );
                },
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _CalorieRing(
                        calories: calories,
                        goal: goal.dailyCalories,
                        progress: caloriePct,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            _MacroProgressRow(
                              label: 'Protein',
                              unit: 'g',
                              value: protein,
                              goal: goal.dailyProtein,
                              color: Colors.blue,
                              icon: Icons.fitness_center_rounded,
                            ),
                            const SizedBox(height: 10),
                            _MacroProgressRow(
                              label: 'Carbs',
                              unit: 'g',
                              value: carbs,
                              goal: goal.dailyCarbs,
                              color: Colors.green,
                              icon: Icons.rice_bowl_rounded,
                            ),
                            const SizedBox(height: 10),
                            _MacroProgressRow(
                              label: 'Fat',
                              unit: 'g',
                              value: fat,
                              goal: goal.dailyFat,
                              color: Colors.redAccent,
                              icon: Icons.oil_barrel_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWaterTrackingCard() {
    return FutureBuilder<double>(
      future: _waterSummaryFuture,
      builder: (context, snapshot) {
        final waterAmount = snapshot.data ?? 0;
        return FutureBuilder<NutritionGoal>(
          future: _nutritionGoalFuture,
          builder: (context, goalSnapshot) {
            final goal = goalSnapshot.data?.dailyWater ?? 2.5;
            final pct = _pct(waterAmount, goal);

            return _SectionCard(
              title: 'Hydration',
              subtitle: 'Stay consistent',
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 70,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 18,
                            backgroundColor: Colors.blue.withOpacity(.10),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF29B6F6),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _WaveOverlayPainter(
                                animationValue:
                                    (DateTime.now().millisecond / 1000),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${waterAmount.toStringAsFixed(2)} L',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Color(0xFF01579B),
                                  ),
                                ),
                                Text(
                                  'Goal ${goal.toStringAsFixed(1)} L',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Log Water'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WaterTrackerPage(
                                  nutritionRepository: _nutritionRepository,
                                  onWaterAdded: _refreshData,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Tooltip(
                        message: 'Quick +250ml',
                        child: Ink(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.local_drink_rounded,
                              color: Colors.blue,
                            ),
                            onPressed: () => _quickAddWater(0.25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentMealsList() {
    return FutureBuilder<List<Meal>>(
      future: _nutritionRepository.getTodayMeals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonCard(height: 160);
        }
        final meals = snapshot.data ?? [];
        final filteredMeals = meals
            .where(
              (m) =>
                  (m.mealType).toLowerCase() == _selectedMealType.toLowerCase(),
            )
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (filteredMeals.isEmpty)
              const _SectionPlaceholder(
                icon: Icons.restaurant_menu_rounded,
                title: 'Nothing logged yet',
                message: 'Tap the selected meal type above to log a meal.',
              )
            else
              Column(
                children: filteredMeals.map((meal) {
                  return Dismissible(
                    key: ValueKey(meal.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    confirmDismiss: (_) async {
                      await _deleteMealWithUndo(meal);
                      return false;
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.withOpacity(.07)),
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
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getMealTypeColor(
                                    meal.mealType,
                                  ).withOpacity(.85),
                                  _getMealTypeColor(
                                    meal.mealType,
                                  ).withOpacity(.55),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _getMealTypeIcon(meal.mealType),
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal.name.isEmpty ? 'Meal' : meal.name,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${meal.calories.toStringAsFixed(0)} kcal • '
                                  '${meal.protein.toStringAsFixed(1)}g P • '
                                  '${meal.carbs.toStringAsFixed(1)}g C • '
                                  '${meal.fat.toStringAsFixed(1)}g Frr ',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever_rounded,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Delete meal',
                            onPressed: () => _deleteMealWithUndo(meal),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSkeletonCard({double height = 140}) {
    return _SectionCard(
      shimmer: true,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: List.generate(
                  4,
                  (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: i == 3 ? 0.0 : 10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.blue;
      case 'snack':
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cake;
      default:
        return Icons.restaurant;
    }
  }

  Widget _buildErrorCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  void _navigateToMealLog(String mealType) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealLogPage(
          nutritionRepository: _nutritionRepository,
          mealType: mealType,
          onMealAdded: _refreshData,
        ),
      ),
    );
    _refreshData();
  }

  Future<void> _deleteMealWithUndo(Meal meal) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('Delete meal?'),
            content: Text('Remove "${meal.name}" from today?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;

    await _nutritionRepository.deleteMeal(meal.id);
    _refreshData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Meal deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await _nutritionRepository.addMeal(meal);
            _refreshData();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Meal restored')));
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final bool shimmer;

  const _SectionCard({
    this.title,
    this.subtitle,
    required this.child,
    this.leading,
    this.trailing,
    this.shimmer = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white, // was Theme.of(context).cardColor.withOpacity(.9)
        border: Border.all(color: Colors.grey.withOpacity(.07)),
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
          if (title != null || leading != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  if (leading != null) leading!,
                  if (leading != null) const SizedBox(width: 12),
                  if (title != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null)
                            Text(
                              title!,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color:
                                    Colors.black87, // ensure visible on white
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          child,
        ],
      ),
    );

    if (!shimmer) return card;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0), // FIX: ensure double literals
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              colors: [
                Colors.white,
                Colors.white,
                Colors.white.withOpacity(.4),
                Colors.white,
              ],
              stops: [0.0, value * 0.5, value * 0.7, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: card,
        );
      },
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _SectionPlaceholder({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final subtle = Colors.grey.shade500;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.grey.withOpacity(.09)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 46, color: subtle),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtle,
              fontSize: 12.5,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Added supporting widgets ---

class _CalorieRing extends StatelessWidget {
  final double calories;
  final double goal;
  final double progress;
  const _CalorieRing({
    required this.calories,
    required this.goal,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final over = calories > goal;
    return SizedBox(
      width: 118,
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(118),
            painter: _RingPainter(progress: progress, over: over),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                calories.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: over ? Colors.redAccent : Colors.black87,
                ),
              ),
              Text(
                '/${goal.toStringAsFixed(0)} kcal',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool over;
  _RingPainter({required this.progress, required this.over});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final rect = Offset.zero & size;
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - stroke / 2;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = LinearGradient(
        colors: [Colors.grey.shade200, Colors.grey.shade100],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 2 * math.pi,
        colors: over
            ? [Colors.redAccent, Colors.red.shade300, Colors.redAccent]
            : [Colors.orange, Colors.deepOrangeAccent, Colors.amber],
        stops: const [0.0, .65, 1.0],
      ).createShader(rect);

    canvas.drawCircle(center, radius, bg);

    final sweep = (progress.clamp(0.0, 1.0).toDouble() * 2 * math.pi);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 2);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      0,
      sweep,
      false,
      fg,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.over != over;
}

class _MacroItem {
  final String name;
  final double value;
  final double goal;
  final Color color;
  _MacroItem({
    required this.name,
    required this.value,
    required this.goal,
    required this.color,
  });
}

class _MacroGrid extends StatelessWidget {
  final List<_MacroItem> items;
  final double Function(double, double) pctBuilder;
  const _MacroGrid({required this.items, required this.pctBuilder});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (m) => Padding(
              padding: EdgeInsets.only(
                bottom: m == items.last ? 0.0 : 10.0, // FIX: double literals
              ),
              child: _MacroChip(item: m, pct: pctBuilder(m.value, m.goal)),
            ),
          )
          .toList(),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final _MacroItem item;
  final double pct;
  const _MacroChip({required this.item, required this.pct});

  @override
  Widget build(BuildContext context) {
    final over = item.value > item.goal;
    return Tooltip(
      message:
          '${item.value.toStringAsFixed(0)} / ${item.goal.toStringAsFixed(0)} g',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: item.color.withOpacity(.08),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: over ? Colors.redAccent : item.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Text(
              '${item.value.toStringAsFixed(0)}g',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: over ? Colors.redAccent : item.color.darken(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation(
                    over ? Colors.redAccent : item.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _ColorShade on Color {
  Color darken([double amount = .18]) {
    final f = 1 - amount;
    return Color.fromARGB(
      alpha,
      (red * f).round(),
      (green * f).round(),
      (blue * f).round(),
    );
  }

  Color lighten([double amount = .18]) {
    return Color.fromARGB(
      alpha,
      red + ((255 - red) * amount).round(),
      green + ((255 - green) * amount).round(),
      blue + ((255 - blue) * amount).round(),
    );
  }
}

class _WaveOverlayPainter extends CustomPainter {
  final double animationValue;
  _WaveOverlayPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const amplitude = 4.0;
    final waveLength = size.width / 1.2;
    final yBase = size.height / 2;
    path.moveTo(0, yBase);
    for (double x = 0; x <= size.width; x++) {
      final y =
          yBase +
          math.sin(
                (x / waveLength * 2 * math.pi) + (animationValue * 2 * math.pi),
              ) *
              amplitude;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(.15), Colors.white.withOpacity(.02)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveOverlayPainter old) =>
      old.animationValue != animationValue;
}

class _ParallaxHeroSlide extends StatelessWidget {
  final String imagePath;
  final String quote;
  final int index;
  final bool active;
  final PageController controller;

  const _ParallaxHeroSlide({
    super.key,
    required this.imagePath,
    required this.quote,
    required this.index,
    required this.controller,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        double page = 0;
        if (controller.hasClients && controller.position.haveDimensions) {
          page = (controller.page ?? controller.initialPage.toDouble()) - index;
        }
        // Parallax offset
        final dx = page * 28;
        final scale = (1 - page.abs() * 0.06).clamp(.9, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(dx, 0),
              child: Transform.scale(
                scale: scale,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            // Soft diagonal sheen
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(.08),
                      Colors.transparent,
                      Colors.black.withOpacity(.25),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Center quote
            Center(
              child: AnimatedOpacity(
                opacity: active ? 1 : 0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                child: _CursiveQuote(quote: quote),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CursiveQuote extends StatelessWidget {
  final String quote;
  const _CursiveQuote({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          quote,
          textAlign: TextAlign.center,
          style: GoogleFonts.greatVibes(
            fontSize: 54,
            height: 1.02,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 30,
                color: Colors.black.withOpacity(.55),
                offset: const Offset(0, 9),
              ),
              Shadow(
                blurRadius: 10,
                color: Colors.black.withOpacity(.35),
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color.withOpacity(.95), color.withOpacity(.70)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .2,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealTypeSegmentedControl extends StatefulWidget {
  final List<String> mealTypes;
  final String current;
  final ValueChanged<String> onChanged;
  final Color Function(String) colorFor;
  final ValueChanged<String>? onLogMeal;

  const _MealTypeSegmentedControl({
    required this.mealTypes,
    required this.current,
    required this.onChanged,
    required this.colorFor,
    this.onLogMeal,
  });

  @override
  State<_MealTypeSegmentedControl> createState() =>
      _MealTypeSegmentedControlState();
}

class _MealTypeSegmentedControlState extends State<_MealTypeSegmentedControl> {
  String? _pressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(.06),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.grey.withOpacity(.15)),
        ),
        height: 70,
        child: Row(
          children: widget.mealTypes.map((t) {
            final selected = t == widget.current;
            final color = widget.colorFor(t);
            final down = _pressed == t;
            return Expanded(
              child: InkWell(
                key: ValueKey('meal-type-$t'),
                splashColor: color.withOpacity(.15),
                highlightColor: color.withOpacity(.10),
                onTap: () {
                  if (t != widget.current) {
                    widget.onChanged(t);
                  } else {
                    widget.onLogMeal?.call(t);
                  }
                },
                onTapDown: (_) => setState(() => _pressed = t),
                onTapCancel: () => setState(() => _pressed = null),
                onTapUp: (_) => setState(() => _pressed = null),
                child: Semantics(
                  button: true,
                  selected: selected,
                  label:
                      '${t[0].toUpperCase()}${t.substring(1)} meal filter${selected ? " (double tap to log)" : ""}',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 230),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: selected
                          ? color.withOpacity(.18)
                          : (down
                                ? Colors.grey.withOpacity(.08)
                                : Colors.transparent),
                      border: selected
                          ? Border.all(color: color.withOpacity(.38), width: 1)
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconFor(t),
                          size: 22,
                          color: selected
                              ? color.darken(.25)
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t[0].toUpperCase() + t.substring(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? color.darken(.35)
                                    : Colors.grey.shade800,
                                letterSpacing: .2,
                              ),
                            ),
                            if (selected)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.add_circle_rounded,
                                  size: 16,
                                  color: color.darken(.25),
                                ),
                              ),
                          ],
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 260),
                          opacity: selected ? 1 : 0,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              height: 3,
                              width: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                gradient: LinearGradient(
                                  colors: [
                                    color.withOpacity(.95),
                                    color.withOpacity(.55),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _iconFor(String t) {
    switch (t) {
      case 'breakfast':
        return Icons.free_breakfast_rounded;
      case 'lunch':
        return Icons.ramen_dining_rounded;
      case 'dinner':
        return Icons.nightlife_rounded;
      case 'snack':
        return Icons.cookie_rounded;
      default:
        return Icons.restaurant;
    }
  }
}

class _MacroProgressRow extends StatelessWidget {
  final String label;
  final String unit;
  final double value;
  final double goal;
  final Color color;
  final IconData icon;

  const _MacroProgressRow({
    required this.label,
    required this.unit,
    required this.value,
    required this.goal,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pct = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0).toDouble();
    final over = value > goal;
    final barColor = over ? Colors.redAccent : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [barColor.withOpacity(.95), barColor.withOpacity(.65)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: barColor.withOpacity(.35),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                        letterSpacing: .2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${value.toStringAsFixed(0)}$unit',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: over ? Colors.redAccent : barColor.darken(.2),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Goal ${goal.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: SizedBox(
                    height: 7,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation(barColor),
                        ),
                        if (over)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.redAccent.withOpacity(.0),
                                    Colors.redAccent.withOpacity(.25),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
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
