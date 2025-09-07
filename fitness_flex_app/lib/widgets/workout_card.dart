import 'package:flutter/material.dart';

class WorkoutCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  // Optional
  final VoidCallback? onFormCheck;   // shows a "Form Checker" button if provided
  final String? duration;            // e.g. "45 min"
  final String? calories;            // e.g. "320 cal"
  final String? level;               // e.g. "Intermediate"
  final Widget? leading;             // optional emoji/icon/avatar at left

  const WorkoutCard({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
    this.onFormCheck,
    this.duration,
    this.calories,
    this.level,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final hasMeta = duration != null || calories != null || level != null;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Slightly smaller leading on very narrow tiles
              final bool narrow = constraints.maxWidth < 340;
              final double leadSize = narrow ? 48 : 56;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    Container(
                      width: leadSize,
                      height: leadSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: leading,
                    ),
                    const SizedBox(width: 12),
                  ],
                  // text + meta + buttons
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // prevent vertical overflow in tight parents
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 6),

                        // Description
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),

                        if (hasMeta) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (duration != null)
                                _metaChip(Icons.access_time, duration!),
                              if (calories != null)
                                _metaChip(Icons.local_fire_department, calories!),
                              if (level != null)
                                _metaChip(Icons.bar_chart, level!),
                            ],
                          ),
                        ],

                        if (onFormCheck != null) ...[
                          const SizedBox(height: 12),
                          // Wrap instead of Row so small widths won’t overflow
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: onFormCheck,
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('Form Checker'),
                              ),
                              OutlinedButton(
                                onPressed: onTap,
                                child: const Text('Open'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
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