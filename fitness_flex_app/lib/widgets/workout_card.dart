import 'package:flutter/material.dart';

class WorkoutCard extends StatelessWidget {
  final String title;
  final String category;
  final String description;
  final String duration;
  final String calories;
  final String difficulty;
  final VoidCallback onTap;

  const WorkoutCard({
    super.key,
    required this.title,
    required this.category,
    required this.description,
    required this.duration,
    required this.calories,
    required this.difficulty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasMeta = duration != null || calories != null || level != null;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.blue.withOpacity(0.2),
        highlightColor: Colors.blue.withOpacity(0.1),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}
