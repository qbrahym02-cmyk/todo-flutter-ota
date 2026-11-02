import 'package:flutter_test/flutter_test.dart';
import 'package:todo_ota/models/task.dart';
import 'package:todo_ota/services/remote_config.dart';

void main() {
  test('Task JSON round-trip', () {
    final t = Task(
      id: '1',
      title: 'اختبار',
      priority: Priority.high,
      dueDate: DateTime(2026, 8, 2),
      createdAt: DateTime(2026, 8, 1),
    );
    final back = Task.decodeList(Task.encodeList([t])).single;
    expect(back.title, 'اختبار');
    expect(back.priority, Priority.high);
    expect(back.dueDate, DateTime(2026, 8, 2));
  });

  test('RemoteConfig parses colors & features', () {
    final c = RemoteConfig.fromJson({
      'app_title': 'X',
      'primary_color': '#FF0000',
      'features': {'stats': false},
      'categories': ['أ', 'ب'],
    });
    expect(c.appTitle, 'X');
    expect(c.primaryColor.toARGB32(), 0xFFFF0000);
    expect(c.featureStats, false);
    expect(c.featurePriorities, true);
    expect(c.categories, ['أ', 'ب']);
  });
}
