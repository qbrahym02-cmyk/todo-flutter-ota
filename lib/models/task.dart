import 'dart:convert';

/// أولوية المهمة
enum Priority { low, medium, high }

extension PriorityX on Priority {
  String get label => switch (this) {
        Priority.low => 'منخفضة',
        Priority.medium => 'متوسطة',
        Priority.high => 'عالية',
      };
}

/// نموذج المهمة
class Task {
  final String id;
  final String title;
  final String note;
  final bool done;
  final Priority priority;
  final String category;
  final DateTime? dueDate;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    this.note = '',
    this.done = false,
    this.priority = Priority.medium,
    this.category = 'عام',
    this.dueDate,
    required this.createdAt,
  });

  bool get isOverdue {
    if (done || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dueDate!.isBefore(today);
  }

  Task copyWith({
    String? title,
    String? note,
    bool? done,
    Priority? priority,
    String? category,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      done: done ?? this.done,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'done': done,
        'priority': priority.index,
        'category': category,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        note: j['note'] as String? ?? '',
        done: j['done'] as bool? ?? false,
        priority: Priority.values[
            ((j['priority'] as num?)?.toInt() ?? 1).clamp(0, Priority.values.length - 1)],
        category: j['category'] as String? ?? 'عام',
        dueDate: j['dueDate'] == null ? null : DateTime.tryParse(j['dueDate'] as String),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  static String encodeList(List<Task> tasks) =>
      jsonEncode(tasks.map((t) => t.toJson()).toList());

  static List<Task> decodeList(String raw) {
    final data = jsonDecode(raw);
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Task.fromJson)
        .toList();
  }
}
