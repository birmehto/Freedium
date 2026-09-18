import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/network/article_url.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_icon_badge.dart';
import '../../../core/widgets/app_textform.dart';
import '../../article/models/saved_article.dart';
import '../../favorites/widgets/favorite_tile.dart';
import '../controllers/library_controller.dart';
import '../models/history_entry.dart';

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
                    onPressed: () => _confirmClear(context),
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
                  ? _buildRecentSearches(context)
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
            Expanded(child: Obx(() => _buildSection(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext context) {
    final theme = Theme.of(context);
    final controller = this.controller;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const Icon(M3EIcons.history_rounded, size: 18),
          const SizedBox(width: 8),
          ...controller.recentSearches.map((query) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(M3EIcons.search_rounded, size: 16),
                label: Text(query),
                onPressed: () => controller.onRecentSearchTap(query),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton(
              onPressed: controller.clearRecentSearches,
              child: Text('Clear', style: theme.textTheme.labelMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context) {
    switch (controller.activeSection.value) {
      case LibrarySection.reading:
        return _buildContinueReading(context);
      case LibrarySection.favorites:
        return _buildFavorites(context);
      case LibrarySection.saved:
        return _buildSaved(context);
      case LibrarySection.history:
        return _buildHistory(context);
    }
  }

  void _openArticle(BuildContext context, String url, {String? title}) {
    final canonical = ArticleUrl.canonicalize(url);
    Get.toNamed(
      AppRoutes.article,
      arguments: {'url': canonical, 'originalUrl': canonical},
    );
  }

  void _openSavedArticle(BuildContext context, SavedArticle saved) {
    Get.toNamed(
      AppRoutes.article,
      arguments: {
        'url': saved.url,
        'originalUrl': saved.url,
        'articleData': {
          'html': saved.html,
          'title': saved.title,
          'author': saved.author,
          'publication': saved.publication,
        },
      },
    );
  }

  String _timeLabel(DateTime? date) {
    if (date == null) return '';
    return DateFormat.yMMMd().add_jm().format(date);
  }

  Widget _buildContinueReading(BuildContext context) {
    final theme = Theme.of(context);
    final themeC = theme.colorScheme;
    final items = controller.continueReading;

    if (items.isEmpty) {
      return const AppEmpty(
        icon: M3EIcons.menu_book_rounded,
        title: 'Nothing in progress',
        subtitle: 'Articles you start reading will show up here so you can pick up where you left off.',
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
            onTap: () => _openArticle(context, entry.url, title: entry.title),
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
                            backgroundColor: themeC.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$percent% read • ${entry.author ?? _timeLabel(entry.lastReadAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: themeC.onSurfaceVariant,
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

  Widget _buildFavorites(BuildContext context) {
    final theme = Theme.of(context);
    final items = controller.filteredFavorites;

    if (items.isEmpty) {
      return AppEmpty(
        icon: controller.searchQuery.isNotEmpty
            ? M3EIcons.search_off_rounded
            : M3EIcons.favorite_rounded,
        title: controller.searchQuery.isNotEmpty
            ? 'No results for "${controller.searchQuery.value}"'
            : 'No favorites yet',
        subtitle: 'Tap the heart while reading an article to save it here.',
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: M3EDismissibleColumn(
        itemCount: items.length,
        style: const M3EDismissibleListStyle(gap: 8),
        onTap: (index) => _openArticle(context, items[index].url),
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

  Widget _buildSaved(BuildContext context) {
    final theme = Theme.of(context);
    final items = controller.filteredSaved;

    if (items.isEmpty) {
      return AppEmpty(
        icon: controller.searchQuery.isNotEmpty
            ? M3EIcons.search_off_rounded
            : M3EIcons.download_rounded,
        title: controller.searchQuery.isNotEmpty
            ? 'No results for "${controller.searchQuery.value}"'
            : 'No saved articles',
        subtitle: 'Use "Save offline" while reading to keep articles for offline reading.',
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: M3EDismissibleColumn(
        itemCount: items.length,
        style: const M3EDismissibleListStyle(gap: 8),
        onTap: (index) => _openSavedArticle(context, items[index]),
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
                '${_timeLabel(item.savedAt)} • ${item.author ?? 'Saved article'}',
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

  Widget _buildHistory(BuildContext context) {
    final theme = Theme.of(context);
    final items = controller.filteredHistory;

    if (items.isEmpty) {
      return AppEmpty(
        icon: controller.searchQuery.isNotEmpty
            ? M3EIcons.search_off_rounded
            : M3EIcons.history_rounded,
        title: controller.searchQuery.isNotEmpty
            ? 'No results for "${controller.searchQuery.value}"'
            : 'No reading history yet',
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
              SizedBox(
                child: M3EListItem(
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
                  onTap: () =>
                      _openArticle(context, entry.url, title: entry.title),
                ),
              ),
              const Divider(height: 1),
            ],
          ],
      ],
    );
  }

  void _confirmClear(BuildContext context) {
    final action = switch (controller.activeSection.value) {
      LibrarySection.reading || LibrarySection.history => 'history',
      LibrarySection.favorites => 'favorites',
      LibrarySection.saved => 'saved articles',
    };

    M3EDialog.show<void>(
      context,
      dialog: Material(
        child: M3EDialog(
          title: 'Clear $action?',
          content: Text('This will permanently delete all your $action.'),
          actions: [
            AppButton(
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(),
              label: const Text('Cancel'),
            ),
            AppButton(
              onPressed: () {
                if (controller.activeSection.value ==
                    LibrarySection.favorites) {
                  controller.clearFavorites();
                } else if (controller.activeSection.value ==
                    LibrarySection.saved) {
                  for (final item in controller.saved) {
                    controller.removeSaved(item.url);
                  }
                } else {
                  controller.clearHistory();
                }
                Navigator.of(context).pop();
              },
              label: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }
}
