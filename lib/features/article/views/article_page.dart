import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(
        title: _displayTitle,
        centerTitle: false,
        actions: [
          Obx(() => _readingTime()),
          const SizedBox(width: 2),
          Obx(() => _favoriteButton(theme)),
          const SizedBox(width: 2),
        ],
      ),
      body: Stack(
        children: [
          Obx(() => ArticleWebView(url: controller.currentUrl.value)),
          Obx(() => _loadingIndicator(theme)),
          const ArticleErrorView(),
          Obx(() => _initialLoader()),
        ],
      ),
      floatingActionButton: _fabMenu(context, theme),
    );
  }

  String get _displayTitle {
    final title = controller.articleTitle.value;
    return title.length > 42 ? '${title.substring(0, 39)}...' : title;
  }

  Widget _readingTime() {
    final minutes = controller.readingTime.value;

    return minutes > 0
        ? AppPill(label: '$minutes min')
        : const SizedBox.shrink();
  }

  Widget _favoriteButton(ThemeData theme) {
    final favorite = controller.isFavorite.value;

    return M3EIconButton(
      size: M3EIconButtonSize.xs,
      icon: Icon(
        favorite ? M3EIcons.favorite_rounded : M3EIcons.favorite_border_rounded,
        color: favorite ? theme.colorScheme.onPrimary : null,
      ),
      tooltip: favorite ? 'Remove from favorites' : 'Save to favorites',
      onPressed: controller.toggleFavorite,
    );
  }

  Widget _loadingIndicator(ThemeData theme) {
    final loading = controller.isLoading.value;
    final progress = controller.loadingProgress.value;

    return AnimatedOpacity(
      opacity: loading ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: M3EProgressIndicator.linear(
            value: progress > 0 && progress < 1 ? progress : null,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _initialLoader() {
    return controller.isInitialLoad.value && controller.errorMessage.isEmpty
        ? const Positioned.fill(child: AppLoading())
        : const SizedBox.shrink();
  }

  Widget _fabMenu(BuildContext context, ThemeData theme) {
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
