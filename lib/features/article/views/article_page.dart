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
        title: Obx(() => Text(_displayTitle)),
        actions: const [
          _ReadingTime(),
          SizedBox(width: AppSpacing.xxs),
          _FavoriteButton(),
          SizedBox(width: AppSpacing.xxs),
        ],
      ),
      body: Stack(
        children: [
          // Deliberately not reactive: the WebView is created once for the
          // initial URL, and later navigations are driven by the controller.
          // Rebuilding it here would reload the article on every page load.
          ArticleWebView(url: controller.currentUrl.value),
          const _LoadingIndicator(),
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
    final minutes = controller.readingTime.value;

    return minutes > 0
        ? AppPill(label: '$minutes min')
        : const SizedBox.shrink();
  }
}

class _FavoriteButton extends GetView<ArticleController> {
  const _FavoriteButton();

  @override
  Widget build(BuildContext context) {
    final favorite = controller.isFavorite;

    return M3EIconButton(
      size: M3EIconButtonSize.xs,
      icon: Icon(
        favorite ? M3EIcons.favorite_rounded : M3EIcons.favorite_border_rounded,
        color: favorite ? context.colors.onPrimary : null,
      ),
      tooltip: favorite ? 'Remove from favorites' : 'Save to favorites',
      onPressed: controller.toggleFavorite,
    );
  }
}

class _LoadingIndicator extends GetView<ArticleController> {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    final loading = controller.isLoading.value;
    final progress = controller.loadingProgress.value;

    return AnimatedOpacity(
      opacity: loading ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child:           M3EProgressIndicator.linear(
            // A determinate bar that is already full, rather than flipping to
            // an indeterminate spinner at exactly 100%.
            value: progress >= 1 ? 1 : (progress > 0 ? progress : null),
            color: context.colors.primary,
          ),
        ),
      ),
    );
  }
}

class _InitialLoader extends GetView<ArticleController> {
  const _InitialLoader();

  @override
  Widget build(BuildContext context) {
    return controller.isInitialLoad.value && controller.errorMessage.isEmpty
        ? const Positioned.fill(child: AppLoading())
        : const SizedBox.shrink();
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
