import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/article_controller.dart';
import '../widgets/article_error.dart';
import '../widgets/article_webview.dart';
import '../widgets/loading.dart';
import '../widgets/reading_settings_sheet.dart';

class ArticlePage extends GetView<ArticleController> {
  const ArticlePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.articleTitle),
        actions: [
          Obx(
            () => M3EIconButton(
              icon: Icon(
                controller.isFavorite.value
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: controller.isFavorite.value
                    ? theme.colorScheme.error
                    : null,
              ),
              onPressed: controller.toggleFavorite,
            ),
          ),
          M3EIconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: controller.shareArticle,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Obx(() {
            if (controller.isLoading.value && !controller.isInitialLoad.value) {
              return LinearProgressIndicator(
                value: controller.loadingProgress.value,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              );
            }

            if (!controller.isInitialLoad.value &&
                controller.scrollProgress.value > 0) {
              return LinearProgressIndicator(
                value: controller.scrollProgress.value,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.secondary.withValues(alpha: 0.8),
                ),
              );
            }

            return const SizedBox.shrink();
          }),
        ),
      ),
      body: Stack(
        children: [
          Obx(() => ArticleWebView(url: controller.currentUrl.value)),

          Obx(() {
            if (controller.errorMessage.isEmpty) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              child: Material(
                color: theme.scaffoldBackgroundColor,
                child: ArticleError(
                  message: controller.errorMessage.value,
                  onRetry: controller.requestRefresh,
                  onOpenBrowser: controller.openInBrowser,
                  onSwitchEngine: controller.tryAlternativeEngine,
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
      bottomNavigationBar: BottomAppBar(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            M3EIconButton(
              icon: const Icon(Icons.settings_suggest_rounded),
              onPressed: () => _showReadingSettings(context),
            ),
            M3EIconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: controller.requestRefresh,
            ),
            M3EIconButton(
              icon: const Icon(Icons.copy_rounded),
              onPressed: controller.copyLink,
            ),
            M3EIconButton(
              icon: const Icon(Icons.open_in_browser_rounded),
              onPressed: controller.openInBrowser,
            ),
          ],
        ),
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
