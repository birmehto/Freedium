import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_pill.dart';
import '../controllers/article_controller.dart';
import '../widgets/article_error_view.dart';
import '../widgets/article_webview.dart';
import '../widgets/reader_settings_sheet.dart';

class ArticlePage extends GetView<ArticleController> {
  const ArticlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        centerTitle: false,
        // Deliberately not the app bar's default titleLarge: a truncated article
        // title competes with the reading-time and favorite actions at 22sp.
        title: Obx(() => Text(_displayTitle, style: context.text.titleMedium)),
        actions: const [
          _ReadingTime(),
          _FavoriteButton(),
          SizedBox(width: AppSpacing.xxs),
        ],
      ),
      body: Stack(
        children: [
          // Deliberately not reactive: the WebView is created once for the
          // initial URL, and later navigations are driven by the controller.
          // Rebuilding it here would reload the article on every page load.
          //
          // Skipped entirely when there is no URL to load: an invalid article
          // URL is reported as an error message, and handing the empty string
          // to the WebView would replace that message with its own error (or a
          // loading timeout) a moment later.
          if (controller.currentUrl.value.isNotEmpty)
            ArticleWebView(url: controller.currentUrl.value),
          const _LoadingIndicator(),
          const _OfflineBanner(),
          const ArticleErrorView(),
          const _InitialLoader(),
        ],
      ),
      floatingActionButton: const _FabMenu(),
    );
  }

  String get _displayTitle {
    final title = controller.articleTitle.value;
    return title.length > 42 ? '${title.substring(0, 39)}...' : title;
  }
}

class _ReadingTime extends GetView<ArticleController> {
  const _ReadingTime();

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

class _FavoriteButton extends GetView<ArticleController> {
  const _FavoriteButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final favorite = controller.isFavorite;

      return M3EIconButton(
        size: M3EIconButtonSize.xs,
        icon: Icon(
          favorite
              ? M3EIcons.favorite_rounded
              : M3EIcons.favorite_border_rounded,
          color: favorite ? context.colors.onPrimary : null,
        ),
        tooltip: favorite ? 'Remove from favorites' : 'Save to favorites',
        onPressed: controller.toggleFavorite,
      );
    });
  }
}

class _LoadingIndicator extends GetView<ArticleController> {
  const _LoadingIndicator();

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

class _InitialLoader extends GetView<ArticleController> {
  const _InitialLoader();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return controller.isInitialLoad.value && controller.errorMessage.isEmpty
          ? const Positioned.fill(child: AppLoading())
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
class _OfflineBanner extends GetView<ArticleController> {
  const _OfflineBanner();

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

class _FabMenu extends GetView<ArticleController> {
  const _FabMenu();

  @override
  Widget build(BuildContext context) {
    return M3EFabMenu(
      size: M3EFabSize.regular,
      icon: const Icon(M3EIcons.more_horiz_rounded),
      items: [
        M3EFabMenuItem(
          icon: const Icon(M3EIcons.read_more_rounded),
          label: 'Reading settings',
          onPressed: () => showReaderSettingsSheet(context),
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
