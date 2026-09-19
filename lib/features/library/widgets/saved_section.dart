import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/widgets/app_icon_badge.dart';
import '../controllers/library_controller.dart';
import 'library_empty_state.dart';
import 'library_shared.dart';

/// Saved (offline) section with swipe-to-delete.
class SavedSection extends StatelessWidget {
  const SavedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<LibraryController>();
    final items = controller.filteredSaved;

    if (items.isEmpty) {
      return const LibraryEmptyState(
        icon: M3EIcons.download_rounded,
        title: 'No saved articles',
        subtitle:
            'Use "Save offline" while reading to keep articles for offline '
            'reading.',
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: M3EDismissibleColumn(
        itemCount: items.length,
        style: const M3EDismissibleListStyle(gap: 8),
        onTap: (index) => openLibrarySavedArticle(items[index]),
        onDismiss: (index, _) async {
          controller.removeSaved(items[index].url);
          return true;
        },
        trailingActionsBuilder: (index) => [
          M3EListSwipeAction(
            icon: const Icon(M3EIcons.delete_rounded),
            isPrimary: true,
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.onErrorContainer,
            onPressed: () => controller.removeSaved(items[index].url),
          ),
        ],
        itemBuilder: (context, index) {
          if (index < 0 || index >= items.length) {
            return const SizedBox.shrink();
          }
          final item = items[index];
          return M3EListItem(
            headline: item.title,
            supportingText:
                '${libraryTimeLabel(item.savedAt)} • '
                '${item.author ?? 'Saved article'}',
            leading: const AppIconBadge(
              icon: M3EIcons.book_rounded,
              size: 44,
              iconSize: 24,
            ),
            trailing: const Icon(M3EIcons.chevron_right_rounded),
          );
        },
      ),
    );
  }
}
