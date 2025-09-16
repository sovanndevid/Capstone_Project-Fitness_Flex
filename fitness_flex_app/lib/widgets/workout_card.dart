import 'package:flutter/material.dart';

class WorkoutCard extends StatelessWidget {
  final String title;
  final String? description;
  final int? duration;
  final int? calories;
  final String? level;
  final String? category;
  final String? difficulty;
  final bool isLiked;
  final VoidCallback? onLike;   // ❤️ toggle
  final VoidCallback? onTap;    // 👆 new tap handler

  const WorkoutCard({
    super.key,
    required this.title,
    this.description,
    this.duration,
    this.calories,
    this.level,
    this.category,
    this.difficulty,
    this.isLiked = false,
    this.onLike,
    this.onTap,  // ✅ added to constructor
  });

  @override
  Widget build(BuildContext context) {
    final hasMeta = duration != null ||
        calories != null ||
        level != null ||
        category != null ||
        difficulty != null;

    return GestureDetector(
      onTap: onTap, // ✅ makes card clickable
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),

              if (description != null) ...[
                const SizedBox(height: 8),
                Text(description!),
              ],

              if (hasMeta) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: [
                    if (duration != null) Text("${duration} min"),
                    if (calories != null) Text("${calories} cal"),
                    if (level != null) Text(level!),
                    if (category != null) Text(category!),
                    if (difficulty != null) Text("Difficulty: $difficulty"),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // ❤️ Like button
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: onLike,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
