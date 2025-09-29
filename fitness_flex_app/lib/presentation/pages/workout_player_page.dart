import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/models/workout_model.dart';

class WorkoutPlayerPage extends StatefulWidget {
  final Workout workout;
  final int initialExerciseIndex;
  final Future<void> Function(
    String workoutId,
    String exerciseId,
    Map<String, dynamic> log,
  )? onSaveSet;

  const WorkoutPlayerPage({
    super.key,
    required this.workout,
    this.initialExerciseIndex = 0,
    this.onSaveSet,
  });

  @override
  State<WorkoutPlayerPage> createState() => _WorkoutPlayerPageState();
}

class _WorkoutPlayerPageState extends State<WorkoutPlayerPage> {
  late int _exIndex;
  int _setIndex = 1;
  bool _resting = false;
  int _restSecondsLeft = 0;
  Timer? _timer;

  final TextEditingController _repsCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _rpeCtrl = TextEditingController();

  WorkoutExercise get ex => widget.workout.exercises[_exIndex];
  bool _isUrl(String s) => s.startsWith('http://') || s.startsWith('https://');

  @override
  void initState() {
    super.initState();
    _exIndex = widget.initialExerciseIndex.clamp(0, widget.workout.exercises.length - 1);
    _prepareForExercise();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _rpeCtrl.dispose();
    super.dispose();
  }

  void _prepareForExercise() {
    _timer?.cancel();
    _resting = false;
    _restSecondsLeft = _parseRestSeconds(ex.restTime);
    _setIndex = 1;
    _repsCtrl.text = ex.reps > 0 ? '${ex.reps}' : '';
    _weightCtrl.text = '';
    _rpeCtrl.text = '';
    setState(() {});
  }

  int _parseRestSeconds(String rest) {
    final s = rest.trim().toLowerCase();
    if (s.isEmpty) return 60;
    if (s.endsWith('s')) return int.tryParse(s.substring(0, s.length - 1)) ?? 60;
    if (s.contains(':')) {
      final p = s.split(':');
      if (p.length == 2) {
        final mm = int.tryParse(p[0]) ?? 0;
        final ss = int.tryParse(p[1]) ?? 0;
        return mm * 60 + ss;
      }
    }
    return int.tryParse(s) ?? 60;
  }

  void _startRest() {
    setState(() {
      _resting = true;
      _restSecondsLeft = _parseRestSeconds(ex.restTime);
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restSecondsLeft <= 1) {
        t.cancel();
        setState(() => _resting = false);
      } else {
        setState(() => _restSecondsLeft -= 1);
      }
    });
  }

  Future<void> _completeSet() async {
    final log = {
      'setIndex': _setIndex,
      'reps': int.tryParse(_repsCtrl.text) ?? ex.reps,
      'weight': double.tryParse(_weightCtrl.text) ?? 0.0,
      'rpe': double.tryParse(_rpeCtrl.text) ?? 0.0,
      'rest': ex.restTime,
      'exerciseName': ex.name,
      'completed': true,
      'ts': DateTime.now().toIso8601String(),
    };

    if (widget.onSaveSet != null) {
      try {
        await widget.onSaveSet!(widget.workout.id, ex.id, log);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save set: $e')),
          );
        }
      }
    }

    if (_setIndex < ex.sets) {
      setState(() => _setIndex += 1);
      _startRest();
    } else {
      _nextExercise();
    }
  }

  void _skipRest() {
    _timer?.cancel();
    setState(() => _resting = false);
  }

  void _nextExercise() {
    _timer?.cancel();
    if (_exIndex < widget.workout.exercises.length - 1) {
      setState(() {
        _exIndex += 1;
        _prepareForExercise();
      });
    } else {
      _finishWorkout();
    }
  }

  void _prevExercise() {
    _timer?.cancel();
    if (_exIndex > 0) {
      setState(() {
        _exIndex -= 1;
        _prepareForExercise();
      });
    }
  }

  void _finishWorkout() {
    _timer?.cancel();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Workout complete 🎉'),
        content: Text('Nice work! You finished “${widget.workout.title}”.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.workout.exercises.length;
    final progress = '${_exIndex + 1} / $total';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.title),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_circle),
            tooltip: 'Finish Workout',
            onPressed: _finishWorkout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.workout.category, style: TextStyle(color: Colors.grey[600])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Exercise $progress',
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(ex.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // media
          _MediaCard(url: ex.imageUrl),
          const SizedBox(height: 16),

          // instructions
          _InstructionsCard(text: ex.description),
          const SizedBox(height: 16),

          // inputs
          Row(
            children: [
              Expanded(child: _NumberField(controller: _repsCtrl, label: 'Reps', hint: ex.reps > 0 ? '${ex.reps}' : '')),
              const SizedBox(width: 12),
              Expanded(child: _NumberField(controller: _weightCtrl, label: 'Weight (kg)', hint: '')),
              const SizedBox(width: 12),
              Expanded(child: _NumberField(controller: _rpeCtrl, label: 'RPE', hint: '7.5')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Set $_setIndex of ${ex.sets}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              _Chip(icon: Icons.timer, label: ex.restTime),
            ],
          ),
          const SizedBox(height: 14),

          // ACTIONS
          if (_resting)
            _RestControls(
              secondsLeft: _restSecondsLeft,
              onSkip: _skipRest,
              onNext: _nextExercise,
            )
          else
            _ActiveControls(
              onPrev: _prevExercise,
              onComplete: _completeSet,
            ),

          const SizedBox(height: 20),

          // quick nav
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < widget.workout.exercises.length; i++)
                ChoiceChip(
                  label: Text(widget.workout.exercises[i].name, overflow: TextOverflow.ellipsis),
                  selected: i == _exIndex,
                  onSelected: (_) {
                    setState(() {
                      _exIndex = i;
                      _prepareForExercise();
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/* -------------------------- sub-widgets -------------------------- */

class _MediaCard extends StatelessWidget {
  const _MediaCard({required this.url});
  final String url;

  bool _isUrl(String s) => s.startsWith('http://') || s.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _isUrl(url)
            ? Image.network(
                url,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    child: child,
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _Shimmer();
                },
                errorBuilder: (_, __, ___) => _MediaFallback(),
              )
            : _MediaFallback(),
      ),
    );
  }
}

class _MediaFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary.withOpacity(0.06),
      child: Center(
        child: Icon(Icons.image_not_supported, size: 42, color: theme.colorScheme.primary.withOpacity(0.6)),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
              stops: [0, (_c.value * 0.5) + 0.25, 1],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(2.0, 0.3),
            ),
          ),
        );
      },
    );
  }
}

class _InstructionsCard extends StatefulWidget {
  const _InstructionsCard({required this.text});
  final String text;

  @override
  State<_InstructionsCard> createState() => _InstructionsCardState();
}

class _InstructionsCardState extends State<_InstructionsCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _expanded ? Icons.expand_less : Icons.expand_more;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: const Text('Instructions', style: TextStyle(fontWeight: FontWeight.w700)),
            trailing: IconButton(icon: Icon(icon), onPressed: () => setState(() => _expanded = !_expanded)),
          ),
          AnimatedCrossFade(
            crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.text.isNotEmpty ? widget.text : 'No instructions available.',
                style: TextStyle(color: Colors.grey[800]),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label, this.hint});
  final TextEditingController controller;
  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActiveControls extends StatelessWidget {
  const _ActiveControls({required this.onPrev, required this.onComplete});
  final VoidCallback onPrev;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Set'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}

class _RestControls extends StatelessWidget {
  const _RestControls({required this.secondsLeft, required this.onSkip, required this.onNext});
  final int secondsLeft;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final mm = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (secondsLeft % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Text('Rest', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('$mm:$ss', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSkip,
                icon: const Icon(Icons.skip_next),
                label: const Text('Skip Rest'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.fast_forward),
                label: const Text('Next Exercise'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
