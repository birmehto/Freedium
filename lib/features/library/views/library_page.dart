import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_textform.dart';
import '../controllers/library_controller.dart';
import '../widgets/favorites_section.dart';
import '../widgets/recent_searches_bar.dart';

class LibraryPage extends GetView<LibraryController> {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Library'),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: AppTextForm(
                variant: M3ETextFieldVariant.outlined,
                label: 'Search your library...',
                onChanged: controller.onSearchChanged,
                leading: const Icon(M3EIcons.search_rounded),
              ),
            ),
            Obx(
              () =>
                  controller.searchQuery.isEmpty &&
                      controller.recentSearches.isNotEmpty
                  ? const RecentSearchesBar()
                  : const SizedBox.shrink(),
            ),
            const Expanded(child: FavoritesSection()),
          ],
        ),
      ),
    );
  }
}
