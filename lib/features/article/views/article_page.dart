import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_pill.dart';
import '../controllers/article_controller.dart';
import '../widgets/article_error_view.dart';
import '../widgets/article_find_bar.dart';
import '../widgets/article_webview.dart';
import '../widgets/reader_settings_sheet.dart';

class ArticlePage extends GetView<ArticleController> {
  const ArticlePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ever(controller.showResumePrompt, (show) {
      if (show) _showResumeDialog(context);
    });

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            controller.startFind,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            controller.saveOffline,
        const SingleActivator(LogicalKeyboardKey.keyD, control: true):
            controller.toggleFavorite,
        const SingleActivator(LogicalKeyboardKey.equal, control: true):
            controller.incrementFontSize,
        const SingleActivator(LogicalKeyboardKey.minus, control: true):
            controller.decrementFontSize,
        const SingleActivator(LogicalKeyboardKey.escape): controller.closeFind,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppAppBar(
            title: _displayTitle,
            centerTitle: false,
            actions: [
              Obx(
                () => controller.isOfflineCopy.value
                    ? const AppPill(label: 'Offline')
                    : const SizedBox.shrink(),
              ),
              Obx(
                () => controller.readingTime.value > 0
                    ? AppPill(label: '${controller.readingTime.value} min read')
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 4),
              M3EIconButton(
                icon: const Icon(M3EIcons.search_rounded),
                tooltip: 'Find in page',
                onPressed: controller.startFind,
              ),
              M3EIconButton(
                icon: const Icon(M3EIcons.share_rounded),
                tooltip: 'Share article',
                onPressed: controller.shareArticle,
              ),
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
                      : 'Save to favorites',
                  onPressed: controller.toggleFavorite,
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Obx(() => ArticleWebView(url: controller.currentUrl.value)),
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
              const ArticleErrorView(),
              Obx(
                () =>
                    controller.isInitialLoad.value &&
                        controller.errorMessage.isEmpty
                    ? const Positioned.fill(child: AppLoading())
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          floatingActionButton: Obx(
            () => controller.isFindActive.value
                ? const ArticleFindBar()
                : M3EFabMenu(
                    icon: const Icon(M3EIcons.more_horiz_rounded),
                    items: _buildFabItems(context, theme),
                  ),
          ),
        ),
      ),
    );
  }

  String get _displayTitle {
    final title = controller.articleTitle.value;
    if (title.length <= 42) return title;
    return '${title.substring(0, 39)}...';
  }

  List<M3EFabMenuItem> _buildFabItems(BuildContext context, ThemeData theme) {
    return [
      M3EFabMenuItem(
        icon: const Icon(M3EIcons.read_more_rounded),
        label: 'Reading settings',
        onPressed: () => showReaderSettingsSheet(context),
      ),
      M3EFabMenuItem(
        icon: const Icon(M3EIcons.search_rounded),
        label: 'Find in page',
        onPressed: controller.startFind,
      ),
      M3EFabMenuItem(
        icon: const Icon(M3EIcons.copy_rounded),
        label: 'Copy link',
        onPressed: controller.copyLink,
      ),
      M3EFabMenuItem(
        icon: const Icon(M3EIcons.content_copy_rounded),
        label: 'Copy article text',
        onPressed: () => _copyArticleText(context),
      ),
      M3EFabMenuItem(
        icon: Icon(
          controller.isSavedOffline.value
              ? M3EIcons.download_done_rounded
              : M3EIcons.download_rounded,
          color: controller.isSavedOffline.value
              ? theme.colorScheme.primary
              : null,
        ),
        label: controller.isSavedOffline.value
            ? 'Delete offline copy'
            : 'Save offline',
        onPressed: controller.isSavedOffline.value
            ? controller.deleteOffline
            : controller.saveOffline,
      ),
      M3EFabMenuItem(
        icon: const Icon(M3EIcons.open_in_browser_rounded),
        label: 'Open in browser',
        onPressed: controller.openInBrowser,
      ),
      M3EFabMenuItem(
        icon: Icon(
          controller.isFavorite.value
              ? M3EIcons.favorite_rounded
              : M3EIcons.favorite_border_rounded,
          color: controller.isFavorite.value ? theme.colorScheme.error : null,
        ),
        label: 'Favorite',
        onPressed: controller.toggleFavorite,
      ),
    ];
  }

  Future<void> _copyArticleText(BuildContext context) async {
    final text = await controller.copyText();
    if (!context.mounted) return;
    final words = text?.trim().isEmpty == false
        ? text!.trim().split(RegExp(r'\s+')).length
        : 0;
    M3ESnackbar.show(
      context,
      message: words > 0
          ? 'Copied $words words to clipboard'
          : 'Nothing to copy yet',
    );
  }

  void _showResumeDialog(BuildContext context) {
    final percent = (controller.resumeProgress.value * 100).round();
    M3EDialog.show<bool>(
      context,
      dialog: Material(
        child: M3EDialog(
          title: 'Continue reading?',
          content: Text(
            'You were $percent% through this article. Pick up where you left '
            'off or start over.',
          ),
          actions: [
            AppButton(
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(false),
              label: const Text('Start over'),
            ),
            AppButton(
              onPressed: () => Navigator.of(context).pop(true),
              label: const Text('Continue'),
            ),
          ],
        ),
      ),
    ).then((resume) {
      if (resume == true) {
        controller.resumeReading();
      } else if (resume == false) {
        controller.startOverReading();
      } else {
        controller.dismissResumePrompt();
      }
    });
  }
}
