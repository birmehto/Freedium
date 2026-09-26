import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/network/article_url.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_textform.dart';
import '../controllers/favorites_controller.dart';
import '../models/favorite_article.dart';
import '../widgets/continue_reading_section.dart';
import '../widgets/delete_favorite_dialog.dart';
import '../widgets/favorite_tile.dart';

class FavoritesPage extends GetView<FavoritesController> {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppAppBar(title: Text('Favorites')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: AppTextForm(
              label: 'Search your library...',
              onChanged: controller.onSearchChanged,
              leading: const Icon(M3EIcons.search_rounded),
            ),
          ),
          // Hidden while searching: a filtered list of favorites is a specific
          // question, and an unrelated reading queue above it is not an answer.
          //
          // The list is read here, inside the Obx, rather than inside
          // ContinueReadingSection: a widget that reads an Rx during its own
          // build is not tracked by the enclosing Obx, so the section would
          // never rebuild once the stored positions arrived.
          Obx(() {
            final items = controller.continueReading;
            final searching = controller.trimmedQuery.isNotEmpty;

            return searching || items.isEmpty
                ? const SizedBox.shrink()
                : ContinueReadingSection(
                    items: items,
                    onOpened: controller.refreshContinueReading,
                  );
          }),
          Expanded(
            child: Obx(() {
              final list = controller.filteredFavorites;
              final isSearching = controller.trimmedQuery.isNotEmpty;

              if (list.isEmpty) {
                return AppEmpty(
                  icon: isSearching
                      ? M3EIcons.search_off_rounded
                      : M3EIcons.auto_awesome_rounded,
                  title: isSearching
                      ? 'No results for\n"${controller.trimmedQuery}"'
                      : 'Your library is empty',
                  subtitle: isSearching
                      ? 'Try a different keyword'
                      : 'Save articles to read them later',
                );
              }

              return M3EDismissibleList(
                // Rebuilt when a swipe is cancelled, so the row that flew out
                // comes back instead of leaving a hole in the list.
                key: ValueKey(controller.dismissEpoch.value),
                itemCount: list.length,
                listPadding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                style: const M3EDismissibleListStyle(gap: 8),
                onTap: (index) async {
                  final item = list[index];
                  final url = ArticleUrl.canonicalize(item.url);

                  await Get.toNamed(
                    AppRoutes.article,
                    arguments: {'url': url, 'originalUrl': url},
                  );

                  // Reading on the other side moved the stored position.
                  await controller.refreshContinueReading();
                },
                onDismiss: (index, _) => _remove(context, list[index]),
                trailingActionsBuilder: (index) => [
                  M3EListSwipeAction(
                    icon: const Icon(M3EIcons.delete_rounded),
                    isPrimary: true,
                    backgroundColor: theme.colorScheme.errorContainer,
                    foregroundColor: theme.colorScheme.onErrorContainer,
                    onPressed: () => _remove(context, list[index]),
                  ),
                ],
                itemBuilder: (context, index) {
                  if (index < 0 || index >= list.length) {
                    return const SizedBox.shrink();
                  }
                  return FavoriteTile(item: list[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Confirms, then removes, [article] from the library.
  ///
  /// Reports back whether the article really left, so a cancelled swipe can
  /// put its row back instead of silently losing it.
  Future<bool> _remove(BuildContext context, FavoriteArticle article) async {
    if (!await showDeleteFavoriteDialog(context, article)) {
      if (context.mounted) controller.dismissEpoch.value++;
      return false;
    }

    await controller.removeFavorite(article.url);
    return true;
  }
}
