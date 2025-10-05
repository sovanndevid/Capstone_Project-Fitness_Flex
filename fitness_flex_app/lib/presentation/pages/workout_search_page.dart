// lib/presentation/pages/workout_search_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/models/exercise.dart';
import 'package:fitness_flex_app/data/repositories/workout_repository.dart';
import 'package:fitness_flex_app/presentation/pages/workout_player_page.dart';

class WorkoutSearchPage extends StatefulWidget {
  const WorkoutSearchPage({super.key, required this.repo});
  final WorkoutRepository repo;

  @override
  State<WorkoutSearchPage> createState() => _WorkoutSearchPageState();
}

class _WorkoutSearchPageState extends State<WorkoutSearchPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  bool _loading = false;
  String _error = '';
  List<Exercise> _results = const [];

  // Filters
  String? _selectedBodyPart;
  String? _selectedEquipment;
  String? _selectedMuscle;

  // Curated chip sets (tweak to taste)
  static const _bodyParts = [
    'chest',
    'back',
    'shoulders',
    'upper arms',
    'lower arms',
    'upper legs',
    'quadriceps',
    'hamstrings',
    'lower legs',
    'waist',
  ];
  static const _equipments = [
    'barbell',
    'dumbbell',
    'kettlebell',
    'cable',
    'body weight',
    'smith machine',
  ];
  static const _muscles = [
    'biceps',
    'triceps',
    'lats',
    'glutes',
    'abs',
    'calves',
    'quads',
    'hamstrings',
    'delts',
    'pecs',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  Future<void> _runSearch() async {
    final q = _controller.text.trim();

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      List<Exercise> hits;
      final hasFilter =
          (_selectedBodyPart != null && _selectedBodyPart!.isNotEmpty) ||
          (_selectedEquipment != null && _selectedEquipment!.isNotEmpty) ||
          (_selectedMuscle != null && _selectedMuscle!.isNotEmpty);

      if (hasFilter) {
        hits = await widget.repo.filterExercises(
          bodyPart: _selectedBodyPart,
          equipment: _selectedEquipment,
          muscle: _selectedMuscle,
        );
      } else {
        hits = q.isEmpty ? const [] : await widget.repo.searchExercises(q);
      }
      setState(() => _results = hits);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleChip<T>(T value, T? current, void Function(T?) assign) {
    if (current == value) {
      assign(null);
    } else {
      assign(value);
    }
    _runSearch();
  }

  bool _isUrl(String s) => s.startsWith('http://') || s.startsWith('https://');

  // --------- Pretty, safe subtitle tags ---------
  String _tags(Exercise e) {
    final parts = <String>{};

    void add(String? s) {
      if (s != null) {
        final t = s.trim();
        if (t.isNotEmpty) parts.add(_titleCase(t));
      }
    }

    // These are safe in your model:
    add(e.bodyPart);
    add(e.equipment);

    // If your model later adds a muscle field (e.g. `muscle` or `primaryMuscle`),
    // you can include it safely like this:
    // try { add((e as dynamic).muscle as String?); } catch (_) {}
    // or map it properly in your Exercise model and call add(e.muscle);

    return parts.join(' • ');
  }

  String _titleCase(String s) {
    return s
        .split(RegExp(r'\s+'))
        .map(
          (w) => w.isEmpty
              ? w
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final canPlay = _results.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            onChanged: _onChanged,
            onSubmitted: (_) => _runSearch(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search exercises (e.g. bench, row, squat, curl)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _FiltersBar(
            bodyParts: _bodyParts,
            equipments: _equipments,
            muscles: _muscles,
            selectedBodyPart: _selectedBodyPart,
            selectedEquipment: _selectedEquipment,
            selectedMuscle: _selectedMuscle,
            onTapBodyPart: (v) => setState(
              () => _toggleChip<String>(
                v,
                _selectedBodyPart,
                (x) => _selectedBodyPart = x,
              ),
            ),
            onTapEquipment: (v) => setState(
              () => _toggleChip<String>(
                v,
                _selectedEquipment,
                (x) => _selectedEquipment = x,
              ),
            ),
            onTapMuscle: (v) => setState(
              () => _toggleChip<String>(
                v,
                _selectedMuscle,
                (x) => _selectedMuscle = x,
              ),
            ),
            onClearAll: () {
              setState(() {
                _selectedBodyPart = null;
                _selectedEquipment = null;
                _selectedMuscle = null;
              });
              _runSearch();
            },
          ),
          const Divider(height: 1),
          Expanded(child: _buildResults(context)),
        ],
      ),
      floatingActionButton: canPlay
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play Results'),
              onPressed: () {
                final title = _controller.text.trim().isNotEmpty
                    ? _controller.text.trim()
                    : [
                        _selectedBodyPart,
                        _selectedEquipment,
                        _selectedMuscle,
                      ].where((e) => e != null && e.isNotEmpty).join(' • ');
                final w = widget.repo.buildInstantWorkout(
                  title: title.isEmpty ? 'Search' : title,
                  items: _results.take(8).toList(),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        WorkoutPlayerPage(workout: w, initialExerciseIndex: 0),
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Type to search ExerciseDB or use the filters above.\n\nTip: combine a Body Part with Equipment!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = _results[i];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _isUrl(e.gifUrl)
                  ? Image.network(
                      e.gifUrl,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 54,
                      height: 54,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      child: const Icon(Icons.image_outlined),
                    ),
            ),
            title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              _tags(e), // ✅ safe & pretty
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_fill),
              onPressed: () {
                final w = widget.repo.buildInstantWorkout(
                  title: e.name,
                  items: [e],
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        WorkoutPlayerPage(workout: w, initialExerciseIndex: 0),
                  ),
                );
              },
              tooltip: 'Play single exercise',
            ),
            onTap: () {
              final w = widget.repo.buildInstantWorkout(
                title: e.name,
                items: [e],
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      WorkoutPlayerPage(workout: w, initialExerciseIndex: 0),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/* -------------------- Filters UI -------------------- */

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.bodyParts,
    required this.equipments,
    required this.muscles,
    required this.selectedBodyPart,
    required this.selectedEquipment,
    required this.selectedMuscle,
    required this.onTapBodyPart,
    required this.onTapEquipment,
    required this.onTapMuscle,
    required this.onClearAll,
  });

  final List<String> bodyParts;
  final List<String> equipments;
  final List<String> muscles;

  final String? selectedBodyPart;
  final String? selectedEquipment;
  final String? selectedMuscle;

  final void Function(String value) onTapBodyPart;
  final void Function(String value) onTapEquipment;
  final void Function(String value) onTapMuscle;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    Widget wrapChips(
      List<String> items,
      String? selected,
      void Function(String) onTap,
    ) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in items)
            ChoiceChip(
              label: Text(s),
              selected: selected == s,
              onSelected: (_) => onTap(s),
            ),
        ],
      );
    }

    final labelStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onClearAll,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Body Part', style: labelStyle),
            const SizedBox(height: 6),
            wrapChips(bodyParts, selectedBodyPart, onTapBodyPart),
            const SizedBox(height: 12),
            Text('Equipment', style: labelStyle),
            const SizedBox(height: 6),
            wrapChips(equipments, selectedEquipment, onTapEquipment),
            const SizedBox(height: 12),
            Text('Muscle', style: labelStyle),
            const SizedBox(height: 6),
            wrapChips(muscles, selectedMuscle, onTapMuscle),
          ],
        ),
      ),
    );
  }
}
