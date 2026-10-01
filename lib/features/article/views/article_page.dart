import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/network/article_resolver.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_pill.dart';
import '../../settings/widgets/reader_appearance_sheet.dart';
import '../controllers/article_controller.dart';
import '../widgets/article_webview.dart';

class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key});

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  /// The controller for this reader, owned by the page.
  ///
  /// Deliberately not registered with GetX: `Get.create` builds a *new*
  /// instance on every `Get.find`, so each widget that looked the controller up
  /// for itself drove a private copy — only the WebView's copy received load
  /// callbacks while every loader's copy stayed at `isLoading = true` forever.
  /// Owning one instance per page also makes opening a second reader
  /// independent of whatever the first one left in the container.
  late final ArticleController controller = ArticleController(
    Get.find<ClipboardService>(),
    Get.find<StorageService>(),
    Get.find<ThemeService>(),
    Get.find<ArticleResolver>(),
  )..onStart();

  @override
  void dispose() {
    controller.onDelete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        centerTitle: false,
        // Deliberately not the app bar's default titleLarge: a truncated article
        // title competes with the reading-time and favorite actions at 22sp.
        title: Obx(() => Text(_displayTitle, style: context.text.titleMedium)),
        actions: [
          _ReadingTime(controller: controller),
          _FavoriteButton(controller: controller),
          const SizedBox(width: AppSpacing.xxs),
        ],
      ),
      body: Stack(
        children: [
          if (controller.currentUrl.value.isNotEmpty)
            ArticleWebView(
              url: controller.currentUrl.value,
              controller: controller,
            ),
          _LoadingIndicator(controller: controller),
          _OfflineBanner(controller: controller),
          _ErrorState(controller: controller),
          _InitialLoader(controller: controller),
        ],
      ),
      floatingActionButton: _FabMenu(controller: controller),
    );
  }

  String get _displayTitle {
    final title = controller.articleTitle.value;
    return title.length > 42 ? '${title.substring(0, 39)}...' : title;
  }
}

/// Full-bleed error state shown inside the article stack when loading fails.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.controller});

  final ArticleController controller;

  @override
  Widget build(BuildContext context) {
    // Reactive: `errorMessage` is set after the page is built, so reading it
    // outside an `Obx` meant this view never appeared.
    return Obx(() {
      final message = controller.errorMessage.value;

      if (message.isEmpty) return const SizedBox.shrink();

      return Positioned.fill(
        child: Material(
          color: context.colors.surface,
          child: AppError(
            title: 'Failed to Load Article',
            message: message,
            onRetry: controller.requestRefresh,
            secondaryLabel: 'Open in Browser',
            onSecondary: controller.openInBrowser,
            hint: 'Try refreshing or opening the article in your browser.',
          ),
        ),
      );
    });
  }
}

class _ReadingTime extends StatelessWidget {
  const _ReadingTime({required this.controller});

  final ArticleController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final minutes = controller.readingTime.value;

      return minutes > 0
          ? AppPill(label: '$minutes min')
          : const SizedBox.shrink();
    });
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.controller});

  final ArticleController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final favorite = controller.isFavorite;
      final busy = controller.isStoringArticle.value;

      return M3EIconButton(
        size: M3EIconButtonSize.xs,
        icon: Icon(
          favorite
              ? M3EIcons.favorite_rounded
              : M3EIcons.favorite_border_rounded,
          color: favorite ? context.colors.onPrimary : null,
        ),
        tooltip: favorite ? 'Remove from favorites' : 'Save to favorites',
        onPressed: busy ? null : controller.toggleFavorite,
      );
    });
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({required this.controller});

  final ArticleController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value;
      final progress = controller.loadingProgress.value;

      return Visibility(
        visible: loading,
        maintainAnimation: true,
        maintainState: true,
        child: Align(
          alignment: Alignment.topCenter,
          child: M3EProgressIndicator.linear(
            // A determinate bar that is already full, rather than flipping to
            // an indeterminate spinner at exactly 100%.
            value: progress >= 1 ? 1 : (progress > 0 ? progress : null),
            color: context.colors.primary,
          ),
        ),
      );
    });
  }
}

class _InitialLoader extends StatelessWidget {
  const _InitialLoader({required this.controller});

  final ArticleController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return controller.isInitialLoad.value && controller.errorMessage.isEmpty
          // Full-bleed, and purely decorative: a drag that happens to start on
          // the spinner belongs to the reader, not to the loading state.
          ? const Positioned.fill(child: IgnorePointer(child: AppLoading()))
          : const SizedBox.shrink();
    });
  }
}

/// Shown while the article on screen is the saved copy rather than a live
/// mirror response.
///
/// A reader who cannot get a connection still expects to know whether they are
/// looking at yesterday's copy, so this is stated rather than left to be
/// guessed from the content.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.controller});

  final ArticleController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final offline = controller.isOffline.value;
      if (!offline) return const SizedBox.shrink();

      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Material(
            color: context.colors.secondaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.full),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    M3EIcons.cloud_off_rounded,
                    size: 18,
                    color: context.colors.onSecondaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      'Offline copy',
                      style: context.text.labelLarge?.copyWith(
                        color: context.colors.onSecondaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  M3EIconButton(
                    size: M3EIconButtonSize.xs,
                    icon: const Icon(M3EIcons.refresh_rounded),
                    tooltip: 'Try loading it again',
                    onPressed: controller.requestRefresh,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _FabMenu extends StatelessWidget {
  const _FabMenu({required this.controller});

  final ArticleController controller;

  @override
  Widget build(BuildContext context) {
    return M3EFabMenu(
      size: M3EFabSize.regular,
      icon: const Icon(M3EIcons.more_horiz_rounded),
      items: [
        M3EFabMenuItem(
          icon: const Icon(M3EIcons.read_more_rounded),
          label: 'Reading settings',
          // The same sheet Settings uses, so reader typography is configured
          // in one place with one set of options.
          onPressed: () => showReaderAppearanceSheet(
            context,
            settings: controller.readingSettings,
            onChanged: controller.updateReaderSettings,
          ),
        ),
        M3EFabMenuItem(
          icon: const Icon(M3EIcons.link_rounded),
          label: 'Copy link',
          onPressed: controller.copyLink,
        ),
        M3EFabMenuItem(
          icon: const Icon(M3EIcons.open_in_browser_rounded),
          label: 'Open in browser',
          onPressed: controller.openInBrowser,
        ),
        M3EFabMenuItem(
          icon: const Icon(M3EIcons.share),
          label: 'Share',
          onPressed: controller.shareArticle,
        ),
      ],
    );
  }
}
