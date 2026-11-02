import 'package:flutter/foundation.dart';

import '../models/task.dart';
import 'task_storage.dart';

enum TaskFilter { all, active, done }

/// منطق إدارة المهام
class TaskController extends ChangeNotifier {
  TaskController(this._storage);

  final TaskStorage _storage;
  final List<Task> _tasks = [];
  TaskFilter filter = TaskFilter.all;
  String? categoryFilter;
  bool loaded = false;

  List<Task> get all => List.unmodifiable(_tasks);
  int get total => _tasks.length;
  int get doneCount => _tasks.where((t) => t.done).length;
  int get activeCount => total - doneCount;

  List<Task> get visible {
    final list = _tasks.where((t) {
      final okFilter = switch (filter) {
        TaskFilter.all => true,
        TaskFilter.active => !t.done,
        TaskFilter.done => t.done,
      };
      final okCat = categoryFilter == null || t.category == categoryFilter;
      return okFilter && okCat;
    }).toList();

    // غير المكتملة أولاً، ثم حسب الأولوية، ثم الموعد، ثم الأحدث
    list.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      final p = b.priority.index.compareTo(a.priority.index);
      if (p != 0) return p;
      if (a.dueDate != null && b.dueDate != null) {
        final d = a.dueDate!.compareTo(b.dueDate!);
        if (d != 0) return d;
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  Future<void> load() async {
    _tasks
      ..clear()
      ..addAll(await _storage.load());
    loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    notifyListeners();
    await _storage.save(_tasks);
  }

  Future<void> add(Task t) async {
    _tasks.add(t);
    await _persist();
  }

  Future<void> update(Task t) async {
    final i = _tasks.indexWhere((x) => x.id == t.id);
    if (i == -1) return;
    _tasks[i] = t;
    await _persist();
  }

  Future<void> toggle(Task t) => update(t.copyWith(done: !t.done));

  Future<Task?> remove(String id) async {
    final i = _tasks.indexWhere((x) => x.id == id);
    if (i == -1) return null;
    final removed = _tasks.removeAt(i);
    await _persist();
    return removed;
  }

  Future<void> clearDone() async {
    _tasks.removeWhere((t) => t.done);
    await _persist();
  }

  void setFilter(TaskFilter f) {
    filter = f;
    notifyListeners();
  }

  void setCategory(String? c) {
    categoryFilter = c;
    notifyListeners();
  }
}
