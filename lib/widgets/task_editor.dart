import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../services/remote_config.dart';
import 'task_tile.dart';

/// نافذة إضافة / تعديل مهمة
class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, required this.config, this.initial});
  final RemoteConfig config;
  final Task? initial;

  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _note = TextEditingController(text: widget.initial?.note);
  late Priority _priority = widget.initial?.priority ?? Priority.medium;
  late String _category = widget.initial?.category ?? widget.config.categories.first;
  late DateTime? _due = widget.initial?.dueDate;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final base = widget.initial;
    final task = base == null
        ? Task(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title,
            note: _note.text.trim(),
            priority: _priority,
            category: _category,
            dueDate: _due,
            createdAt: DateTime.now(),
          )
        : base.copyWith(
            title: title,
            note: _note.text.trim(),
            priority: _priority,
            category: _category,
            dueDate: _due,
            clearDueDate: _due == null,
          );
    Navigator.pop(context, task);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (d != null) setState(() => _due = d);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    final categories = {...cfg.categories, _category}.toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.initial == null ? 'مهمة جديدة' : 'تعديل المهمة',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              autofocus: widget.initial == null,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                hintText: cfg.addHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'ملاحظات (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            if (cfg.featurePriorities) ...[
              const SizedBox(height: 16),
              const Text('الأولوية'),
              const SizedBox(height: 6),
              SegmentedButton<Priority>(
                segments: [
                  for (final p in Priority.values)
                    ButtonSegment(
                      value: p,
                      label: Text(p.label),
                      icon: Icon(Icons.circle, size: 12, color: priorityColor(p)),
                    ),
                ],
                selected: {_priority},
                onSelectionChanged: (s) => setState(() => _priority = s.first),
              ),
            ],
            if (cfg.featureCategories) ...[
              const SizedBox(height: 16),
              const Text('التصنيف'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  for (final c in categories)
                    ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
            ],
            if (cfg.featureDueDates) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event),
                    label: Text(_due == null
                        ? 'إضافة موعد'
                        : DateFormat('EEEE d MMMM', 'ar').format(_due!)),
                  ),
                  if (_due != null)
                    IconButton(
                      onPressed: () => setState(() => _due = null),
                      icon: const Icon(Icons.close),
                      tooltip: 'إزالة الموعد',
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('حفظ'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }
}
