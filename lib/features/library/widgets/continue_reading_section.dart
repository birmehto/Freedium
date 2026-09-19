import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_icon_badge.dart';
import '../controllers/library_controller.dart';
import 'library_shared.dart';

/// Continue Reading section: in-progress articles with progress bars.
class ContinueReadingSection extends StatelessWidget {
  const ContinueReadingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final items = Get.find<LibraryController>().continueReading;

    if (items.isEmpty) {
      return const AppEmpty(
        icon: M3EIcons.menu_book_rounded,
        title: 'Nothing in progress',
        subtitle:
            'Articles you start reading will show up here so you can pick up '
            'where you left off.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = items[index];
        final percent = (entry.progress * 100).round();
        return M3ECard(
          variant: M3ECardVariant.filled,
          child: InkWell(
            onTap: () => openLibraryArticle(entry.url, title: entry.title),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const AppIconBadge(
                    icon: M3EIcons.menu_book_rounded,
                    size: 44,
                    iconSize: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.progress,
                            minHeight: 6,
                            backgroundColor: c.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$percent% read • '
                          '${entry.author ?? libraryTimeLabel(entry.lastReadAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: c.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(M3EIcons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
