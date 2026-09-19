import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_textform.dart';
import '../controllers/library_controller.dart';
import '../widgets/continue_reading_section.dart';
import '../widgets/favorites_section.dart';
import '../widgets/history_section.dart';
import '../widgets/library_shared.dart';
import '../widgets/recent_searches_bar.dart';
import '../widgets/saved_section.dart';

class LibraryPage extends GetView<LibraryController> {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Library',
        actions: [
          Obx(
            () => controller.visibleCount > 0 && controller.searchQuery.isEmpty
                ? TextButton(
                    onPressed: () => confirmClearLibrary(context),
                    child: const Text('Clear'),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Obx(
                () => SegmentedButton<LibrarySection>(
                  segments: const [
                    ButtonSegment(
                      value: LibrarySection.reading,
                      label: Text('Continue'),
                      icon: Icon(M3EIcons.menu_book_rounded),
                    ),
                    ButtonSegment(
                      value: LibrarySection.favorites,
                      label: Text('Favorites'),
                      icon: Icon(M3EIcons.favorite_rounded),
                    ),
                    ButtonSegment(
                      value: LibrarySection.saved,
                      label: Text('Saved'),
                      icon: Icon(M3EIcons.download_rounded),
                    ),
                    ButtonSegment(
                      value: LibrarySection.history,
                      label: Text('History'),
                      icon: Icon(M3EIcons.history_rounded),
                    ),
                  ],
                  selected: {controller.activeSection.value},
                  onSelectionChanged: (selection) =>
                      controller.onSectionChanged(selection.first),
                  showSelectedIcon: false,
                ),
              ),
            ),
            Expanded(child: Obx(() => _buildSection())),
          ],
        ),
      ),
    );
  }

  Widget _buildSection() {
    switch (controller.activeSection.value) {
      case LibrarySection.reading:
        return const ContinueReadingSection();
      case LibrarySection.favorites:
        return const FavoritesSection();
      case LibrarySection.saved:
        return const SavedSection();
      case LibrarySection.history:
        return const HistorySection();
    }
  }
}
