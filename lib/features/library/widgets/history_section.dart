import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/widgets/app_icon_badge.dart';
import '../controllers/library_controller.dart';
import '../models/history_entry.dart';
import 'library_empty_state.dart';
import 'library_shared.dart';

/// History section grouped by recency (Today / Yesterday / This week / Earlier).
class HistorySection extends StatelessWidget {
  const HistorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<LibraryController>();
    final items = controller.filteredHistory;

    if (items.isEmpty) {
      return const LibraryEmptyState(
        icon: M3EIcons.history_rounded,
        title: 'No reading history yet',
        subtitle: 'Articles you open will appear here.',
      );
    }

    final groups = <String, List<HistoryEntry>>{};
    for (final entry in items) {
      groups.putIfAbsent(entry.timeBucket, () => []).add(entry);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        for (final bucket in ['Today', 'Yesterday', 'This week', 'Earlier'])
          if ((groups[bucket] ?? []).isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Text(
                bucket.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.primary.withValues(alpha: 0.85),
                ),
              ),
            ),
            for (final entry in groups[bucket]!) ...[
              M3EListItem(
                headline: entry.title,
                supportingText: [
                  if (entry.progress > 0 && !entry.completed)
                    '${(entry.progress * 100).round()}% read',
                  entry.author,
                  if (entry.saved) 'Saved' else null,
                ].whereType<String>().join(' • '),
                leading: AppIconBadge(
                  icon: entry.completed
                      ? M3EIcons.check_circle_rounded
                      : M3EIcons.history_rounded,
                  size: 44,
                  iconSize: 24,
                ),
                trailing: const Icon(M3EIcons.chevron_right_rounded),
                onTap: () => openLibraryArticle(entry.url, title: entry.title),
              ),
              const Divider(height: 1),
            ],
          ],
      ],
    );
  }
}
