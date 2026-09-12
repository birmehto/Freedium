import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_textform.dart';
import '../controllers/favorites_controller.dart';
import '../widgtes/favorite_tile.dart';

class FavoritesPage extends GetView<FavoritesController> {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppAppBar(title: 'Favorites'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppTextForm(
              
              label: 'Search your library...',
              onChanged: controller.onSearchChanged,
              prefixIcon: const Icon(M3EIcons.search_rounded),
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

              return Padding(
                padding: const EdgeInsets.all(16),
                child: M3EDismissibleColumn(
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
                      onPressed: () =>
                          controller.removeFavorite(list[index].url),
                    ),
                  ],
                  itemBuilder: (context, index) =>
                      FavoriteTile(item: list[index]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
