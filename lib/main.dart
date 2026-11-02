import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_screen.dart';
import 'services/remote_config.dart';
import 'services/task_controller.dart';
import 'services/task_storage.dart';
import 'services/update_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');

  final remote = RemoteConfigService();
  final tasks = TaskController(TaskStorage());
  final updates = UpdateService();

  // التحميل في الخلفية — الواجهة تظهر فوراً
  tasks.load();
  remote.init();
  updates.check();

  runApp(TodoApp(remote: remote, tasks: tasks, updates: updates));
}

class TodoApp extends StatefulWidget {
  const TodoApp({
    super.key,
    required this.remote,
    required this.tasks,
    required this.updates,
  });

  final RemoteConfigService remote;
  final TaskController tasks;
  final UpdateService updates;

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// كل ما يرجع المستخدم للتطبيق نجلب آخر الإعدادات ونفحص التحديثات
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.remote.refresh();
      widget.updates.check();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.remote,
      builder: (context, _) {
        final cfg = widget.remote.config;
        final brightness = cfg.darkMode ? Brightness.dark : Brightness.light;
        return MaterialApp(
          title: cfg.appTitle,
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: cfg.primaryColor,
              brightness: brightness,
            ),
          ),
          home: HomeScreen(
            remote: widget.remote,
            tasks: widget.tasks,
            updates: widget.updates,
          ),
        );
      },
    );
  }
}
