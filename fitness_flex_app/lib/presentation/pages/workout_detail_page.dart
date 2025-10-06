import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/models/workout_model.dart';
import 'package:fitness_flex_app/presentation/pages/workout_player_page.dart';

class WorkoutDetailPage extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailPage({super.key, required this.workout});

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  late bool _isFav;

  @override
  void initState() {
    super.initState();
    _isFav = widget.workout.isFavorite;
  }

  bool _isUrl(String s) {
    final u = Uri.tryParse(s);
    return u != null && (u.hasScheme && (u.scheme == 'http' || u.scheme == 'https'));
  }

  Color _difficultyColor(String difficulty, BuildContext context) {
    switch (difficulty.toLowerCase()) {
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
    final diffColor = _difficultyColor(widget.workout.difficulty, context);

    return Scaffold(
      backgroundColor: Colors.white, // <-- solid white background as requested
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white, // solid white app bar
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        title: Text(
          widget.workout.title,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            tooltip: 'Favorite',
            icon: Icon(
              _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFav ? Colors.pinkAccent : Colors.black87,
            ),
            onPressed: () {
              setState(() => _isFav = !_isFav);
              // Wire to your repository here if needed
            },
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover + category
            _Card(
              child: Row(
                children: [
                  _CoverThumb(urlOrEmoji: widget.workout.imageUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.workout.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: .2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.workout.category,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(.65),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Meta chips
            _Card(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(icon: Icons.access_time_rounded, text: widget.workout.duration),
                  _MetaChip(icon: Icons.local_fire_department_rounded, text: '${widget.workout.calories} cal'),
                  _Pill(text: _cap(widget.workout.difficulty), color: diffColor),
                ],
              ),
            ),

            if (widget.workout.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Description
              _Card(
                child: Text(
                  widget.workout.description,
                  style: TextStyle(
                    color: Colors.black.withOpacity(.85),
                    fontSize: 14.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Primary CTA
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutPlayerPage(
                        workout: widget.workout,
                        initialExerciseIndex: 0,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Exercises
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.view_list_rounded, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Exercises',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: .2,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Column(
              children: List.generate(widget.workout.exercises.length, (i) {
                final e = widget.workout.exercises[i];
                return _ExerciseTile(
                  index: i + 1,
                  exercise: e,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutPlayerPage(
                          workout: widget.workout,
                          initialExerciseIndex: i,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/* ─────────────────────── Minimal UI Pieces ─────────────────────── */

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding, this.radius});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius ?? 18),
        border: Border.all(color: Colors.black.withOpacity(.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CoverThumb extends StatelessWidget {
  const _CoverThumb({required this.urlOrEmoji});
  final String urlOrEmoji;

  bool _isUrl(String s) {
    final u = Uri.tryParse(s);
    return u != null && (u.hasScheme && (u.scheme == 'http' || u.scheme == 'https'));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.primary.withOpacity(.10);

    if (_isUrl(urlOrEmoji)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          urlOrEmoji,
          width: 84,
          height: 84,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(bg),
          loadingBuilder: (ctx, child, progress) => progress == null ? child : _fallback(bg),
        ),
      );
    }
    return _fallback(bg, emoji: urlOrEmoji.isNotEmpty ? urlOrEmoji : '🏋️');
  }

  Widget _fallback(Color bg, {String emoji = '🏋️'}) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 34)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: onSurface.withOpacity(.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: onSurface.withOpacity(.75)),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              color: onSurface.withOpacity(.95),
              fontWeight: FontWeight.w800,
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.32)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: _darken(color, .2)),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.index, required this.exercise, required this.onTap});
  final int index;
  final WorkoutExercise exercise;
  final VoidCallback onTap;

  bool _isUrl(String s) {
    final u = Uri.tryParse(s);
    return u != null && (u.hasScheme && (u.scheme == 'http' || u.scheme == 'https'));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    final subtitle = StringBuffer();
    if (exercise.description.isNotEmpty) {
      final d = exercise.description.length > 100
          ? '${exercise.description.substring(0, 100)}…'
          : exercise.description;
      subtitle.writeln(d);
    }
    subtitle.write('${exercise.sets} sets × ${exercise.reps} reps');
    if (exercise.restTime.isNotEmpty) subtitle.write('  •  Rest ${exercise.restTime}');
    if (exercise.duration.isNotEmpty) subtitle.write('  •  ${exercise.duration}');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // index badge
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$index', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 10),
              // image / emoji
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _isUrl(exercise.imageUrl)
                    ? Image.network(
                        exercise.imageUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackThumb(cs),
                        loadingBuilder: (ctx, child, progress) => progress == null ? child : _fallbackThumb(cs),
                      )
                    : _fallbackThumb(cs, emoji: '💪'),
              ),
              const SizedBox(width: 12),
              // texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black.withOpacity(.75),
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.play_circle_fill_rounded, color: cs.primary, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackThumb(ColorScheme cs, {String emoji = '🏋️'}) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 22)),
    );
  }
}
