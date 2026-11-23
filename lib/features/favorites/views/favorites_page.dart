import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/animation/app_animator.dart';
import '../../../core/controllers/app_controllers.dart';
import '../../../core/controllers/app_shell_controller.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/theme/app_theme.dart';
import '../../article/models/article_request.dart';
import '../../article/views/article_page.dart';
import '../controllers/favorites_controller.dart';
import '../models/favorite_article.dart';
import '../widgets/delete_favorite_dialog.dart';
import '../widgets/favorite_tile.dart';

/// The saved-story shelf: a masthead, a hairline search field and a list of
/// titles separated by rules rather than cards.
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryControllerProvider);
    final favoritesState = ref.watch(favoritesControllerProvider);
    final controller = ref.read(favoritesControllerProvider.notifier);
    final list = controller.filteredFavorites;
    final query = controller.trimmedQuery;
    final isSearching = query.isNotEmpty;

    final ink = AppTheme.ink(context);
    final muted = AppTheme.muted(context);
    final rule = AppTheme.rule(context);

    return Scaffold(
      backgroundColor: AppTheme.paper(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SAVED STORIES',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: muted, letterSpacing: 1.6),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your library',
                    style: GoogleFonts.sourceSerif4(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: ink,
                      letterSpacing: -1.2,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: ink)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.search, size: 18, color: muted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        onChanged: controller.onSearchChanged,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: ink),
                        decoration: InputDecoration(
                          hintText: 'Search your library',
                          hintStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: muted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: list.isEmpty
                  ? AppAnimator.entrance(
                      child: _EmptyState(
                        isSearching: isSearching,
                        query: query,
                        isLibraryEmpty: library.isEmpty,
                        onStart: () => ref
                            .read(appShellTabProvider.notifier)
                            .selectTab(AppShellTab.home),
                      ),
                    )
                  : ListView.separated(
                      // Bumped when a swipe is cancelled so every row is rebuilt
                      // in place instead of leaving a hole in the list.
                      key: ValueKey(favoritesState.dismissEpoch),
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: rule),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return Dismissible(
                          key: ValueKey(item.url),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: const Color(0xFFB3261E),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              LucideIcons.trash2,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) =>
                              _confirmRemove(context, ref, item),
                          onDismissed: (_) {},
                          child: FavoriteTile(
                            item: item,
                            onTap: () => pushPage(
                              ArticlePage(
                                request: ArticleRequest(url: item.url),
                              ),
                            ),
                            onDelete: () =>
                                unawaited(_confirmRemove(context, ref, item)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirms, then removes, [item] from the library via the dialog.
  ///
  /// A full swipe reports both the auto-run delete action and the list's own
  /// dismiss; the controller's guard makes sure only one dialog is pushed.
  Future<bool> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    FavoriteArticle item,
  ) async {
    final controller = ref.read(favoritesControllerProvider.notifier);
    if (!controller.startRemovalConfirm(item.url)) return false;

    bool confirmed;
    try {
      confirmed = await showDeleteFavoriteDialog(
        context,
        url: item.url,
        title: item.title,
      );
    } finally {
      controller.endRemovalConfirm(item.url);
    }

    if (!confirmed) {
      // The swiped row is still mounted; rebuild the list so it snaps back.
      controller.bumpDismissEpoch();
    }
    return confirmed;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isSearching,
    required this.query,
    required this.isLibraryEmpty,
    required this.onStart,
  });

  final bool isSearching;
  final String query;
  final bool isLibraryEmpty;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final ink = AppTheme.ink(context);
    final muted = AppTheme.muted(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 28, height: 2, child: ColoredBox(color: ink)),
              const SizedBox(height: 24),
              Text(
                isSearching ? 'No matches' : 'No favorites yet',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: ink),
              ),
              const SizedBox(height: 12),
              Text(
                isSearching
                    ? 'Nothing in your library matches “$query”.'
                    : 'Open any Medium link from Home, then tap the heart on '
                          'the article to save it here for offline reading.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: muted, height: 1.5),
              ),
              if (isSearching) ...[
                const SizedBox(height: 12),
                Text(
                  'Try a different keyword',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: muted),
                ),
              ] else if (isLibraryEmpty) ...[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: onStart,
                  child: const Text('Start reading'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
