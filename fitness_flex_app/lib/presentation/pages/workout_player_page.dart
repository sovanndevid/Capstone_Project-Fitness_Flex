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
    _exIndex = widget.initialExerciseIndex.clamp(
      0,
      widget.workout.exercises.length - 1,
    );
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
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
      // Keep the app background neutral
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.workout.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_circle_outlined),
            tooltip: 'Finish Workout',
            onPressed: _finishWorkout,
          ),
        ],
      ),

      // FIXED BOTTOM BAR — swaps based on _resting
      bottomNavigationBar: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _resting
              ? _BottomBar(
                  key: const ValueKey('rest'),
                  child: _RestControlsBar(
                    secondsLeft: _restSecondsLeft,
                    onSkip: _skipRest,
                    onNext: _nextExercise,
                  ),
                )
              : _BottomBar(
                  key: const ValueKey('active'),
                  child: _ActiveControlsBar(
                    onPrev: _prevExercise,
                    onComplete: _completeSet,
                  ),
                ),
        ),
      ),

      // CONTENT CARD to avoid big black areas in dark mode
      body: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Card with rounded top corners holding all content
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Player
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _ResponsivePlayer(imageUrl: ex.imageUrl, isUrl: _isUrl),
                  ),

                  // Title + meta
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      ex.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(text: widget.workout.category, icon: Icons.fitness_center_outlined),
                        _MetaPill(text: 'Exercise $progress', icon: Icons.list_alt_outlined),
                        _MetaPill(text: 'Set $_setIndex of ${ex.sets}', icon: Icons.repeat_on_outlined),
                        _MetaPill(text: ex.restTime, icon: Icons.timer_outlined),
                      ],
                    ),
                  ),

                  // Inputs
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _RoundField(
                            controller: _repsCtrl,
                            label: 'Reps',
                            hint: ex.reps > 0 ? '${ex.reps}' : '',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _RoundField(
                            controller: _weightCtrl,
                            label: 'Weight (kg)',
                            hint: '',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _RoundField(
                            controller: _rpeCtrl,
                            label: 'RPE',
                            hint: '7.5',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Description (instructions)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _DescriptionBlock(text: ex.description),
                  ),

                  // Up next
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // leave space for bottom bar
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Up next',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (int i = 0; i < widget.workout.exercises.length; i++)
                              ChoiceChip(
                                label: Text(
                                  widget.workout.exercises[i].name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                selected: i == _exIndex,
                                labelStyle: TextStyle(
                                  color: i == _exIndex
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                ),
                                selectedColor: theme.colorScheme.primary,
                                backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------- Responsive Player (border + contain) -------------------------- */

class _ResponsivePlayer extends StatelessWidget {
  const _ResponsivePlayer({required this.imageUrl, required this.isUrl});
  final String imageUrl;
  final bool Function(String) isUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * 9 / 16; // YouTube-like height

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface, // no black
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: isUrl(imageUrl)
              ? Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,          // fits big/small GIFs
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    frameBuilder: (context, child, frame, wasSync) {
                      if (wasSync) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 250),
                        child: child,
                      );
                    },
                    errorBuilder: (_, __, ___) => const _PlayerErrorIcon(),
                  ),
                )
              : const _PlayerErrorIcon(),
        );
      },
    );
  }
}

class _PlayerErrorIcon extends StatelessWidget {
  const _PlayerErrorIcon();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
        size: 48,
      ),
    );
  }
}

/* -------------------------- Fixed Bottom Bars -------------------------- */

class _BottomBar extends StatelessWidget {
  const _BottomBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.4))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: child,
    );
  }
}

class _ActiveControlsBar extends StatelessWidget {
  const _ActiveControlsBar({required this.onPrev, required this.onComplete});
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
              shape: const StadiumBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Complete Set'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class _RestControlsBar extends StatelessWidget {
  const _RestControlsBar({
    required this.secondsLeft,
    required this.onSkip,
    required this.onNext,
  });
  final int secondsLeft;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final mm = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (secondsLeft % 60).toString().padLeft(2, '0');
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSkip,
            icon: const Icon(Icons.skip_next_rounded),
            label: const Text('Skip Rest'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const StadiumBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.fast_forward_rounded),
            label: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Next Exercise'),
                const SizedBox(width: 8),
                Text(
                  '$mm:$ss',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimary.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

/* -------------------------- Description / Inputs / Meta -------------------------- */

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionBlock extends StatefulWidget {
  const _DescriptionBlock({required this.text});
  final String text;

  @override
  State<_DescriptionBlock> createState() => _DescriptionBlockState();
}

class _DescriptionBlockState extends State<_DescriptionBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = widget.text.trim().isNotEmpty;
    final display = hasText ? widget.text.trim() : 'No instructions available.';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: const Text('Description', style: TextStyle(fontWeight: FontWeight.w800)),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(display, style: TextStyle(color: Colors.grey[800], height: 1.35)),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _RoundField extends StatelessWidget {
  const _RoundField({required this.controller, required this.label, this.hint = ''});
  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: theme.colorScheme.surface,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(50),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
          borderRadius: BorderRadius.circular(50),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
