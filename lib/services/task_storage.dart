import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

/// تخزين المهام محلياً على الجهاز
class TaskStorage {
  static const _key = 'tasks_v1';

  Future<List<Task>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return Task.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, Task.encodeList(tasks));
  }
}
