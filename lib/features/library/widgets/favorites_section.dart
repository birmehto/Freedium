import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../favorites/widgets/favorite_tile.dart';
import '../controllers/library_controller.dart';
import 'library_empty_state.dart';
import 'library_shared.dart';

/// Favorites section with swipe-to-delete.
class FavoritesSection extends StatelessWidget {
  const FavoritesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<LibraryController>();
    final items = controller.filteredFavorites;

    if (items.isEmpty) {
      return const LibraryEmptyState(
        icon: M3EIcons.favorite_rounded,
        title: 'No favorites yet',
        subtitle: 'Tap the heart while reading an article to save it here.',
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: M3EDismissibleColumn(
        itemCount: items.length,
        style: const M3EDismissibleListStyle(gap: 8),
        onTap: (index) => openLibraryArticle(items[index].url),
        onDismiss: (index, _) async {
          await controller.removeFavorite(items[index].url);
          return true;
        },
        trailingActionsBuilder: (index) => [
          M3EListSwipeAction(
            icon: const Icon(M3EIcons.delete_rounded),
            isPrimary: true,
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.onErrorContainer,
            onPressed: () => controller.removeFavorite(items[index].url),
          ),
        ],
        itemBuilder: (context, index) {
          if (index < 0 || index >= items.length) {
            return const SizedBox.shrink();
          }
          return FavoriteTile(item: items[index]);
        },
      ),
    );
  }
}
