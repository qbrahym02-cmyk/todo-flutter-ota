import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../services/remote_config.dart';
import '../services/task_controller.dart';
import '../services/update_service.dart';
import '../widgets/task_editor.dart';
import '../widgets/task_tile.dart';
import '../widgets/update_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.remote,
    required this.tasks,
    required this.updates,
  });

  final RemoteConfigService remote;
  final TaskController tasks;
  final UpdateService updates;

  Future<void> _refresh() async {
    await Future.wait([remote.refresh(), updates.check()]);
  }

  Future<void> _openEditor(BuildContext context, RemoteConfig cfg, [Task? task]) async {
    final result = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TaskEditor(config: cfg, initial: task),
    );
    if (result == null) return;
    if (task == null) {
      await tasks.add(result);
    } else {
      await tasks.update(result);
    }
  }

  Future<void> _delete(BuildContext context, Task t) async {
    final removed = await tasks.remove(t.id);
    if (removed == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('تم حذف "${removed.title}"'),
        action: SnackBarAction(label: 'تراجع', onPressed: () => tasks.add(removed)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([remote, tasks, updates]),
      builder: (context, _) {
        final cfg = remote.config;
        final scheme = Theme.of(context).colorScheme;
        final visible = tasks.visible;

        return Scaffold(
          appBar: AppBar(
            title: Text(cfg.appTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'clear') await tasks.clearDone();
                  if (v == 'update' && context.mounted) {
                    await updates.check();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(updates.isAvailable
                          ? 'يوجد تحديث جديد: ${updates.latest!.version}'
                          : updates.state == UpdateState.error
                              ? 'تعذّر الفحص: ${updates.error}'
                              : 'أنت على آخر إصدار ✅'),
                    ));
                  }
                  if (v == 'about' && context.mounted) _about(context);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'update', child: Text('البحث عن تحديث')),
                  PopupMenuItem(value: 'clear', child: Text('حذف المكتملة')),
                  PopupMenuItem(value: 'about', child: Text('حول التطبيق')),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openEditor(context, cfg),
            icon: const Icon(Icons.add),
            label: const Text('مهمة جديدة'),
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: UpdateBanner(updates: updates)),
                if (cfg.announcementEnabled && cfg.announcementText.isNotEmpty)
                  SliverToBoxAdapter(child: _Announcement(cfg: cfg)),
                if (cfg.featureStats && tasks.total > 0)
                  SliverToBoxAdapter(child: _StatsCard(tasks: tasks)),
                SliverToBoxAdapter(child: _Filters(tasks: tasks, cfg: cfg)),
                if (!tasks.loaded)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.checklist_rounded, size: 72, color: scheme.primary.withValues(alpha: .4)),
                          const SizedBox(height: 12),
                          Text(cfg.emptyMessage, style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                    sliver: SliverList.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, i) {
                        final t = visible[i];
                        return TaskTile(
                          key: ValueKey(t.id),
                          task: t,
                          config: cfg,
                          onToggle: () => tasks.toggle(t),
                          onTap: () => _openEditor(context, cfg, t),
                          onDelete: () => _delete(context, t),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _about(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: remote.config.appTitle,
      applicationVersion:
          '${updates.currentVersion} (build ${updates.currentBuild}) • config v${remote.config.configVersion}',
      children: [
        Text('آخر فحص: ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}'),
        const SizedBox(height: 8),
        const Text('يتم تحديث الإعدادات والتطبيق تلقائياً عن بُعد.'),
      ],
    );
  }
}

class _Announcement extends StatelessWidget {
  const _Announcement({required this.cfg});
  final RemoteConfig cfg;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cfg.announcementColor.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cfg.announcementColor.withValues(alpha: .4)),
      ),
      child: Row(
        children: [
          Icon(Icons.campaign_rounded, color: cfg.announcementColor),
          const SizedBox(width: 10),
          Expanded(child: Text(cfg.announcementText)),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.tasks});
  final TaskController tasks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = tasks.total == 0 ? 0.0 : tasks.doneCount / tasks.total;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('إنجازك', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('${(ratio * 100).round()}%',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold, color: scheme.primary)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: ratio, minHeight: 8),
            ),
            const SizedBox(height: 10),
            Text('${tasks.doneCount} مكتملة • ${tasks.activeCount} متبقية • ${tasks.total} الكل'),
          ],
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.tasks, required this.cfg});
  final TaskController tasks;
  final RemoteConfig cfg;

  @override
  Widget build(BuildContext context) {
    const labels = {
      TaskFilter.all: 'الكل',
      TaskFilter.active: 'النشطة',
      TaskFilter.done: 'المكتملة',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<TaskFilter>(
            segments: [
              for (final e in labels.entries) ButtonSegment(value: e.key, label: Text(e.value)),
            ],
            selected: {tasks.filter},
            onSelectionChanged: (s) => tasks.setFilter(s.first),
          ),
          if (cfg.featureCategories) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ChoiceChip(
                      label: const Text('كل التصنيفات'),
                      selected: tasks.categoryFilter == null,
                      onSelected: (_) => tasks.setCategory(null),
                    ),
                  ),
                  for (final c in cfg.categories)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: tasks.categoryFilter == c,
                        onSelected: (_) => tasks.setCategory(c),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
