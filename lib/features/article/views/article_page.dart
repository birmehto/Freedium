import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/animation/app_animator.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/widgets/reader_appearance_sheet.dart';
import '../controllers/article_controller.dart';
import '../models/article_request.dart';
import '../widgets/article_webview.dart';

/// The reader screen: a WebView wrapped in the app's editorial chrome.
///
/// One [ArticleController] is owned by the page and shared with the WebView so
/// its load callbacks and the loaders above it observe the very same state.
class ArticlePage extends ConsumerStatefulWidget {
  const ArticlePage({super.key, required this.request});

  final ArticleRequest request;

  @override
  ConsumerState<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends ConsumerState<ArticlePage> {
  late final ArticleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(articleControllerProvider.notifier);
    // Exactly one load per page instance. Rebuilding must not re-open the URL.
    // Deferring to the post-frame phase keeps the synchronous state reset in
    // `open()` out of Flutter's build phase, where Riverpod forbids writes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_controller.open(widget.request));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(articleControllerProvider);
    final ink = AppTheme.ink(context);
    final muted = AppTheme.muted(context);
    final rule = AppTheme.rule(context);
    final paper = AppTheme.paper(context);

    final rawTitle = state.articleTitle;
    final displayTitle = rawTitle.length > 42
        ? '${rawTitle.substring(0, 39)}…'
        : rawTitle;

    return Scaffold(
      backgroundColor: paper,
      appBar: AppBar(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 21),
          color: ink,
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          displayTitle.isEmpty ? 'Article' : displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: ink),
        ),
        actions: [
          if (state.readingTime > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  '${state.readingTime} min read',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: muted),
                ),
              ),
            ),
          AppAnimator.pulse(
            value: state.isFavorite,
            child: IconButton(
              icon: Icon(
                // Lucide is outline-only, so the saved state uses the filled
                // Material heart to make "already in the library" unmistakable.
                state.isFavorite ? Icons.favorite : LucideIcons.heart,
                size: 21,
                color: state.isFavorite ? AppTheme.accent(context) : ink,
              ),
              tooltip: state.isFavorite
                  ? 'Remove from library'
                  : 'Save to library',
              onPressed: state.isStoringArticle
                  ? null
                  : _controller.toggleFavorite,
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: rule),
        ),
      ),
      body: Stack(
        children: [
          if (state.currentUrl.isNotEmpty)
            ArticleWebView(url: state.currentUrl, controller: _controller),
          if (state.isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  value: state.loadingProgress >= 1
                      ? 1
                      : (state.loadingProgress > 0
                            ? state.loadingProgress
                            : null),
                  backgroundColor: Colors.transparent,
                  color: AppTheme.accent(context),
                  minHeight: 2,
                ),
              ),
            ),
          if (state.isOffline)
            Positioned(
              top: 2,
              left: 0,
              right: 0,
              child: AppAnimator.entrance(
                child: _OfflineBanner(controller: _controller),
              ),
            ),
          if (state.errorMessage.isNotEmpty)
            Positioned.fill(
              child: AppAnimator.entrance(
                child: _ErrorState(state: state, controller: _controller),
              ),
            ),
          if (state.isInitialLoad && state.errorMessage.isEmpty)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _ActionStrip(controller: _controller),
    );
  }
}

/// Full-bleed editorial failure state shown above the WebView.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.state, required this.controller});

  final ArticleState state;
  final ArticleController controller;

  @override
  Widget build(BuildContext context) {
    final ink = AppTheme.ink(context);
    final muted = AppTheme.muted(context);
    final rule = AppTheme.rule(context);

    return ColoredBox(
      color: AppTheme.paper(context),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 32, height: 2, child: ColoredBox(color: ink)),
                const SizedBox(height: 24),
                Text(
                  'Couldn’t load this story',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(color: ink),
                ),
                const SizedBox(height: 12),
                Text(
                  state.errorMessage,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: muted, height: 1.5),
                ),
                const SizedBox(height: 28),
                Divider(height: 1, color: rule),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: controller.requestRefresh,
                  child: const Text('Try again'),
                ),
                TextButton(
                  onPressed: controller.openInBrowser,
                  child: const Text('Open in browser'),
                ),
                const SizedBox(height: 12),
                Text(
                  'The reader tries other sources automatically. If none work, '
                  'a saved copy is used when one is available.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A thin amber strip telling the reader the document on screen is a saved copy.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.controller});

  final ArticleController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFB26A00),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(LucideIcons.cloudOff, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          const Text(
            'Offline copy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          InkResponse(
            onTap: controller.requestRefresh,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact, quiet action strip in place of a floating colored FAB menu.
class _ActionStrip extends StatelessWidget {
  const _ActionStrip({required this.controller});

  final ArticleController controller;

  @override
  Widget build(BuildContext context) {
    final rule = AppTheme.rule(context);
    final ink = AppTheme.ink(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paper(context),
        border: Border(top: BorderSide(color: rule)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Action(
                icon: LucideIcons.palette,
                label: 'Style',
                color: ink,
                onTap: () => showReaderAppearanceSheet(context),
              ),
              _Action(
                icon: LucideIcons.share2,
                label: 'Share',
                color: ink,
                onTap: controller.shareArticle,
              ),
              _Action(
                icon: LucideIcons.externalLink,
                label: 'Browser',
                color: ink,
                onTap: controller.openInBrowser,
              ),
              _Action(
                icon: LucideIcons.refreshCw,
                label: 'Refresh',
                color: ink,
                onTap: controller.requestRefresh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.muted(context);
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21, color: onTap == null ? muted : color),
            const SizedBox(height: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: onTap == null ? muted : color),
            ),
          ],
        ),
      ),
    );
  }
}
