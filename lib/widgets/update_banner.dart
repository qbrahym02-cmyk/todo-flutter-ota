import 'package:flutter/material.dart';

import '../services/update_service.dart';

/// شريط يظهر أعلى الشاشة عند توفر إصدار جديد
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key, required this.updates});
  final UpdateService updates;

  @override
  Widget build(BuildContext context) {
    final s = updates.state;
    final show = updates.isAvailable &&
        (s == UpdateState.available ||
            s == UpdateState.downloading ||
            s == UpdateState.installing ||
            s == UpdateState.error);
    if (!show) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final rel = updates.latest!;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.system_update_rounded, color: scheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  updates.isForced
                      ? 'تحديث إلزامي متوفر (${rel.version})'
                      : 'إصدار جديد متوفر: ${rel.version}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
          if (rel.changelog.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(rel.changelog, style: TextStyle(color: scheme.onTertiaryContainer)),
          ],
          const SizedBox(height: 10),
          if (s == UpdateState.downloading) ...[
            LinearProgressIndicator(value: updates.progress == 0 ? null : updates.progress),
            const SizedBox(height: 4),
            Text('جاري التنزيل ${(updates.progress * 100).round()}%'),
          ] else if (s == UpdateState.installing)
            const Text('جاري فتح شاشة التثبيت...')
          else ...[
            if (s == UpdateState.error)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('خطأ: ${updates.error}', style: TextStyle(color: scheme.error)),
              ),
            FilledButton.icon(
              onPressed: updates.install,
              icon: const Icon(Icons.download_rounded),
              label: const Text('تحديث الآن'),
            ),
          ],
        ],
      ),
    );
  }
}
