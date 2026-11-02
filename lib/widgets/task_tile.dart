import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../services/remote_config.dart';

Color priorityColor(Priority p) => switch (p) {
      Priority.low => const Color(0xFF22C55E),
      Priority.medium => const Color(0xFFF59E0B),
      Priority.high => const Color(0xFFEF4444),
    };

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.config,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  final Task task;
  final RemoteConfig config;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Dismissible(
      key: ValueKey('dismiss-${task.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: AlignmentDirectional.centerEnd,
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: task.done ? .35 : .7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                if (config.featurePriorities)
                  Container(
                    width: 4,
                    height: 40,
                    margin: const EdgeInsetsDirectional.only(start: 6),
                    decoration: BoxDecoration(
                      color: priorityColor(task.priority),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                Checkbox(
                  value: task.done,
                  onChanged: (_) => onToggle(),
                  shape: const CircleBorder(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: text.titleMedium?.copyWith(
                          decoration: task.done ? TextDecoration.lineThrough : null,
                          color: task.done ? scheme.outline : null,
                        ),
                      ),
                      if (task.note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            task.note,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(color: scheme.outline),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (config.featureCategories)
                            _Pill(icon: Icons.label_outline, text: task.category),
                          if (config.featureDueDates && task.dueDate != null)
                            _Pill(
                              icon: Icons.event,
                              text: DateFormat('d MMM', 'ar').format(task.dueDate!),
                              color: task.isOverdue ? scheme.error : null,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: c)),
        ],
      ),
    );
  }
}
