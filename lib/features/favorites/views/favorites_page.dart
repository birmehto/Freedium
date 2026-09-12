import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/utils/url_validator.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_icon_badge.dart';
import '../controllers/favorites_controller.dart';
import '../models/favorite_article.dart';

class FavoritesPage extends GetView<FavoritesController> {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: M3ETextField(
            label: 'Search your library...',
            onChanged: controller.onSearchChanged,
            leading: const Padding(
              padding: EdgeInsets.only(left: 4.0),
              child: Icon(M3EIcons.search_rounded),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            final list = controller.filteredFavorites;
            final isSearching = controller.searchQuery.isNotEmpty;

            if (list.isEmpty) {
              return AppEmpty(
                icon: isSearching
                    ? M3EIcons.search_off_rounded
                    : M3EIcons.auto_awesome_rounded,
                title: isSearching
                    ? 'No results for\n"${controller.searchQuery.value}"'
                    : 'Your library is empty',
                subtitle: isSearching
                    ? 'Try a different keyword'
                    : 'Save articles to read them later',
              );
            }

            return M3EDismissibleColumn(
              itemCount: list.length,
              onDismiss: (index, _) async {
                await controller.removeFavorite(list[index].url);
                return true;
              },
              trailingActionsBuilder: (index) => [
                M3EListSwipeAction(
                  icon: const Icon(M3EIcons.delete_rounded),
                  isPrimary: true,
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                  onPressed: () => controller.removeFavorite(list[index].url),
                ),
              ],
              itemBuilder: (context, index) => _FavoriteTile(item: list[index]),
            );
          }),
        ),
      ],
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.item});

  final FavoriteArticle item;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    final meta = <String?>[
      item.author,
      item.domain,
      DateFormat.yMMMd().add_jm().format(item.visitedAt),
    ].whereType<String>().join(' • ');

    return M3EListItem(
      headline: item.title.isNotEmpty ? item.title : 'Untitled Article',
      supportingText: meta,
      leading: AppIconBadge(
        icon: M3EIcons.auto_stories_rounded,
        size: 48,
        iconSize: 26,
        iconColor: c.primary,
      ),
      trailing: const Icon(M3EIcons.chevron_right_rounded),
      onTap: () {
        final url = item.url;
        final freedium = UrlValidator.convertToFreediumUrl(url) ?? url;
        Get.toNamed(
          AppRoutes.article,
          arguments: {'url': freedium, 'originalUrl': url},
        );
      },
    );
  }
}
