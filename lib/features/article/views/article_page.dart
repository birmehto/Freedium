import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_pill.dart';
import '../controllers/article_controller.dart';
import '../widgets/article_webview.dart';

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
            () => controller.readingTime.value > 0
                ? AppPill(label: '${controller.readingTime.value} min read')
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 4),
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

          // Loading progress bar.
          Obx(
            () => AnimatedOpacity(
              opacity: controller.isLoading.value ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: M3EProgressIndicator.linear(
                    value:
                        controller.loadingProgress.value > 0 &&
                            controller.loadingProgress.value < 1.0
                        ? controller.loadingProgress.value
                        : null,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),

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
      bottomNavigationBar: Material(
        color: theme.colorScheme.surfaceContainer,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
                  icon: const Icon(M3EIcons.format_size_rounded),
                  tooltip: 'Reading settings',
                  onPressed: () => _showAppearanceSheet(context),
                ),
                M3EIconButton(
                  icon: const Icon(M3EIcons.copy_rounded),
                  tooltip: 'Copy link',
                  onPressed: controller.copyLink,
                ),
                M3EIconButton(
                  icon: const Icon(M3EIcons.open_in_browser_rounded),
                  tooltip: 'Open in browser',
                  onPressed: controller.openInBrowser,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAppearanceSheet(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final controller = Get.find<ArticleController>();

    final sheet = Material(
      color: c.surfaceContainer,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: c.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Reading Settings', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),

              // Font size
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Font Size', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Obx(
                          () => Text(
                            '${controller.fontSize.value.toStringAsFixed(0)} px',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Decrease font size',
                    onPressed: controller.decrementFontSize,
                    icon: const Icon(M3EIcons.remove_rounded),
                  ),
                  Obx(
                    () => SizedBox(
                      width: 160,
                      child: M3ESlider(
                        value: controller.fontSize.value,
                        min: AppConstants.minFontSize,
                        max: AppConstants.maxFontSize,
                        divisions:
                            ((AppConstants.maxFontSize -
                                        AppConstants.minFontSize) ~/
                                    AppConstants.fontSizeStep)
                                .toInt(),
                        label: controller.fontSize.value.toStringAsFixed(0),
                        onChanged: controller.setFontSize,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Increase font size',
                    onPressed: controller.incrementFontSize,
                    icon: const Icon(M3EIcons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Reset font size
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: controller.resetFontSize,
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Get.bottomSheet(
      sheet,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
