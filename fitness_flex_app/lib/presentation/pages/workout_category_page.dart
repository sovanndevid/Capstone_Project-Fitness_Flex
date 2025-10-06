import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/models/workout_model.dart';
import 'package:fitness_flex_app/data/repositories/workout_repository.dart';
import 'package:fitness_flex_app/presentation/pages/workout_detail_page.dart';

class WorkoutCategoryPage extends StatefulWidget {
  final WorkoutRepository workoutRepository;
  final WorkoutCategory category; // enum

  const WorkoutCategoryPage({
    super.key,
    required this.workoutRepository,
    required this.category,
  });

  @override
  State<WorkoutCategoryPage> createState() => _WorkoutCategoryPageState();
}

class _WorkoutCategoryPageState extends State<WorkoutCategoryPage> {
  late Future<List<Workout>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.workoutRepository.getWorkoutsByCategory(widget.category.wire);
  }

  void _refresh() => setState(_load);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Scaffold(
      extendBody: true,
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 4),
            _MiniLogoBadge(emoji: widget.category.emoji),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.category.name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: onSurface,
                    ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary.withOpacity(.06), cs.surface, cs.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<Workout>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _ErrorCard(message: 'Error: ${snapshot.error}'),
                ),
              );
            }

            final workouts = snapshot.data ?? const <Workout>[];
            if (workouts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _EmptyCard(
                    title: 'No workouts found',
                    subtitle: 'There are no plans in ${widget.category.name} right now.',
                    icon: Icons.fitness_center_rounded,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: workouts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _WorkoutRowCard(workout: workouts[i]),
            );
          },
        ),
      ),
    );
  }
}

/* ───────────────────────── Cards & Pieces ───────────────────────── */

class _WorkoutRowCard extends StatelessWidget {
  const _WorkoutRowCard({required this.workout});
  final Workout workout;

  String _difficultyLabel(String raw) => WorkoutDifficulty.fromWire(raw).name;

  Color _difficultyColor(String label, BuildContext context) {
    switch (label.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.redAccent;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final diffLabel = _difficultyLabel(workout.difficulty);
    final diffColor = _difficultyColor(diffLabel, context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF141A2B) : Colors.white).withOpacity(.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .35 : .08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WorkoutDetailPage(workout: workout)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThumbIcon(char: workout.imageUrl.isNotEmpty ? workout.imageUrl.characters.first : '🏋️'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workout.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, color: onSurface.withOpacity(.8), height: 1.25),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatChip(icon: Icons.access_time_rounded, text: workout.duration),
                        _StatChip(icon: Icons.local_fire_department_rounded, text: '${workout.calories} cal'),
                        _Pill(text: diffLabel, color: diffColor),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StartButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: onSurface.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: onSurface.withOpacity(.75)),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12.5, color: onSurface.withOpacity(.9), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  Color _darken(Color c, [double amount = .18]) {
    final f = 1 - amount;
    return Color.fromARGB(c.alpha, (c.red * f).round(), (c.green * f).round(), (c.blue * f).round());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.32)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _darken(color, .2)),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ElevatedButton(
      onPressed: null, // purely visual; tap the card to open details
      style: ElevatedButton.styleFrom(
        backgroundColor: primary.withOpacity(.12),
        foregroundColor: primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: const StadiumBorder(),
      ),
      child: const Text('Start', style: TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _ThumbIcon extends StatelessWidget {
  const _ThumbIcon({required this.char});
  final String char;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1A2135) : const Color(0xFFF0F3F7)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Center(child: Text(char, style: const TextStyle(fontSize: 24))),
    );
  }
}

class _MiniLogoBadge extends StatelessWidget {
  const _MiniLogoBadge({this.emoji});
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9B5EFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(.16),
              border: Border.all(color: Colors.white.withOpacity(.35)),
            ),
          ),
          if (emoji == null || emoji!.isEmpty)
            const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 18)
          else
            Text(emoji!, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF141A2B) : Colors.white).withOpacity(.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(.06)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: cs.onSurface.withOpacity(.45)),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurface.withOpacity(.7))),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
