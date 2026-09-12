import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import '../controllers/article_controller.dart';
import '../widgets/article_webview.dart';
import '../widgets/reading_settings_sheet.dart';

class ArticlePage extends GetView<ArticleController> {
  const ArticlePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(
        title: controller.articleTitle,
        centerTitle: false,
        actions: [
          Obx(
            () => M3EIconButton(
              icon: Icon(
                controller.isFavorite.value
                    ? M3EIcons.favorite_rounded
                    : M3EIcons.favorite_border_rounded,
                color: controller.isFavorite.value
                    ? theme.colorScheme.error
                    : null,
              ),
              tooltip: controller.isFavorite.value
                  ? 'Remove from favorites'
                  : 'Add to favorites',
              onPressed: controller.toggleFavorite,
            ),
          ),
          M3EIconButton(
            icon: const Icon(M3EIcons.share_rounded),
            tooltip: 'Share article',
            onPressed: controller.shareArticle,
          ),
        ],
      ),
      body: Stack(
        children: [
          Obx(() => ArticleWebView(url: controller.currentUrl.value)),

          Obx(() {
            final Widget bar;
            if (controller.isLoading.value && !controller.isInitialLoad.value) {
              bar = M3EProgressIndicator.linear(
                value: controller.loadingProgress.value,
                color: theme.colorScheme.primary,
              );
            } else if (!controller.isInitialLoad.value &&
                controller.scrollProgress.value > 0) {
              bar = M3EProgressIndicator.linear(
                value: controller.scrollProgress.value,
                color: theme.colorScheme.secondary.withValues(alpha: 0.8),
              );
            } else {
              bar = const SizedBox.shrink();
            }

            return Align(alignment: Alignment.topCenter, child: bar);
          }),

          Obx(() {
            if (controller.errorMessage.isEmpty) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              child: Material(
                color: theme.scaffoldBackgroundColor,
                child: AppError(
                  title: 'Failed to Load Article',
                  message: controller.errorMessage.value,
                  onRetry: controller.requestRefresh,
                  secondaryLabel: 'Open in Browser',
                  onSecondary: controller.openInBrowser,
                  hint:
                      'Try refreshing or opening the article in your browser.',
                ),
              ),
            );
          }),

          Obx(
            () => controller.isInitialLoad.value
                ? const Positioned.fill(child: AppLoading())
                : const SizedBox.shrink(),
          ),
        ],
      ),
      bottomNavigationBar: M3EToolbar.docked(
        actions: [
          M3EToolbarAction(
            icon: M3EIcons.settings_suggest_rounded,
            tooltip: 'Reading settings',
            onPressed: () => _showReadingSettings(context),
          ),
          M3EToolbarAction(
            icon: M3EIcons.refresh_rounded,
            tooltip: 'Refresh',
            onPressed: controller.requestRefresh,
          ),
          M3EToolbarAction(
            icon: M3EIcons.copy_rounded,
            tooltip: 'Copy link',
            onPressed: controller.copyLink,
          ),
          M3EToolbarAction(
            icon: M3EIcons.open_in_browser_rounded,
            tooltip: 'Open in browser',
            onPressed: controller.openInBrowser,
          ),
        ],
      ),
    );
  }

  void _showReadingSettings(BuildContext context) {
    M3EBottomSheet.show<void>(
      context,
      builder: (_) => const ReadingSettingsSheet(),
    );
  }
}
