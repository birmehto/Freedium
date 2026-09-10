import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../shared/widgets/app_animations.dart';
import '../../../../shared/widgets/app_page.dart';
import '../controllers/favorites_controller.dart';
import '../widgets/favorites_list_item.dart';

class FavoritesPage extends GetView<FavoritesController> {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPage(
      title: 'Favorites',
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      slivers: [
        const SizedBox(height: 8),

        FadeSlideIn(
          child: M3ETextField(
            label: 'Search your library...',
            onChanged: controller.onSearchChanged,
            leading: const Padding(
              padding: EdgeInsets.only(left: 4.0),
              child: Icon(Icons.search_rounded),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Obx(() {
          final list = controller.filteredFavorites;
          final isSearching = controller.searchQuery.isNotEmpty;

          if (list.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: FadeSlideIn(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSearching
                              ? Icons.search_off_rounded
                              : Icons.auto_awesome_rounded,
                          size: 80,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        isSearching
                            ? 'No results for\n"${controller.searchQuery.value}"'
                            : 'Your library is empty',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isSearching
                            ? 'Try a different keyword'
                            : 'Save articles to read them later',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = list[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FadeSlideIn(
                  delay: Duration(milliseconds: 50 * index),
                  child: FavoritesListItem(
                    item: item,
                    onDelete: () => controller.removeFavorite(item.url),
                  ),
                ),
              );
            }, childCount: list.length),
          );
        }),
      ],
    );
  }
}
