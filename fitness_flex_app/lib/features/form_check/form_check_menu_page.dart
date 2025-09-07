import 'package:flutter/material.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';

class FormCheckMenuPage extends StatelessWidget {
  const FormCheckMenuPage({super.key});

  static const _exercises = <String>[
    'Back Squat', 'Push-up', 'Deadlift', 'Bench Press',
    'Overhead Press', 'Lunge', 'Bent-over Row', 'Plank',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          iconColor: Colors.grey,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Select Exercise')),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _exercises.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final name = _exercises[i];
            return Card(
              child: ListTile(
                leading: _iconFor(name),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRouter.formCheck,
                    arguments: {'exercise': name},
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _iconFor(String name) {
    IconData icon = Icons.fitness_center;
    if (name.contains('Squat')) icon = Icons.accessibility_new;
    if (name.contains('Push-up')) icon = Icons.push_pin_outlined;
    if (name.contains('Deadlift')) icon = Icons.back_hand_outlined;
    if (name.contains('Bench')) icon = Icons.bed_outlined;
    if (name.contains('Press')) icon = Icons.arrow_circle_up_outlined;
    if (name.contains('Lunge')) icon = Icons.directions_walk;
    if (name.contains('Row')) icon = Icons.rowing;
    if (name.contains('Plank')) icon = Icons.straighten;
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey.shade200,
      child: Icon(icon, size: 20, color: Colors.grey.shade800),
    );
  }
}