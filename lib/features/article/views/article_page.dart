import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_pill.dart';
import '../../settings/models/reader_settings.dart';
import '../../settings/models/reader_theme_mode.dart';
import '../controllers/article_controller.dart';
import '../widgets/article_webview.dart';

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

              Obx(() => _buildErrorState(context, theme)),

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
                ? _buildFindBar(context)
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
        onPressed: () => _showAppearanceSheet(context),
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

  Widget _buildErrorState(BuildContext context, ThemeData theme) {
    if (controller.errorMessage.isEmpty) return const SizedBox.shrink();

    return Positioned.fill(
      child: Material(
        color: theme.scaffoldBackgroundColor,
        child: AppError(
          title: 'Failed to Load Article',
          message: controller.errorMessage.value,
          onRetry: controller.requestRefresh,
          secondaryLabel: 'Open in Browser',
          onSecondary: controller.openInBrowser,
          hint: 'Try refreshing or opening the article in your browser.',
          extraActions: [
            if (controller.savedCopyAvailable.value)
              AppButton(
                variant: AppButtonVariant.tonal,
                onPressed: controller.openSavedCopy,
                isFullWidth: true,
                icon: const Icon(M3EIcons.download_rounded, size: 20),
                label: const Text('Open saved copy'),
              ),
            if (!controller.savedCopyAvailable.value)
              AppButton(
                variant: AppButtonVariant.tonal,
                onPressed: controller.tryNextMirror,
                isFullWidth: true,
                icon: const Icon(M3EIcons.swap_horiz_rounded, size: 20),
                label: const Text('Try another source'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFindBar(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 24, 16),
        child: Material(
          color: c.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: c.outlineVariant),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Icon(M3EIcons.search_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    autofocus: true,
                    onChanged: controller.onFindQueryChanged,
                    onSubmitted: (_) => controller.findNext(true),
                    decoration: const InputDecoration(
                      hintText: 'Find in article',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => Text(
                    controller.findMatchCount.value > 0
                        ? '${controller.findMatchIndex.value}/${controller.findMatchCount.value}'
                        : '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ),
                M3EIconButton(
                  icon: const Icon(M3EIcons.keyboard_arrow_up_rounded),
                  tooltip: 'Previous match',
                  onPressed: () => controller.findNext(false),
                ),
                M3EIconButton(
                  icon: const Icon(M3EIcons.keyboard_arrow_down_rounded),
                  tooltip: 'Next match',
                  onPressed: () => controller.findNext(true),
                ),
                M3EIconButton(
                  icon: const Icon(M3EIcons.close_rounded),
                  tooltip: 'Close find',
                  onPressed: controller.closeFind,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
            'You were $percent% through this article. Pick up where you left off or start over.',
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

  void _showAppearanceSheet(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final settings = controller.readingSettings.value;

    Widget chipRow(
      String title,
      List<String> labels,
      String selected,
      ValueChanged<String> onSelected,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in labels)
                ChoiceChip(
                  label: Text(label),
                  selected: selected == label,
                  onSelected: (_) => onSelected(label),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      );
    }

    final sheet = Material(
      color: c.surfaceContainer,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Obx(() {
            final current = controller.readingSettings.value;
            return Column(
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

                chipRow(
                  'Theme',
                  ReaderThemeMode.values.map((m) => m.label).toList(),
                  current.themeMode.label,
                  (label) => controller.updateReaderSettings(
                    current.copyWith(
                      themeMode: ReaderThemeMode.values.firstWhere(
                        (m) => m.label == label,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                chipRow(
                  'Font family',
                  const ['System', 'Georgia', 'Inter', 'Merriweather'],
                  current.fontFamily,
                  (label) => controller.updateReaderSettings(
                    current.copyWith(fontFamily: label),
                  ),
                ),

                _sliderRow(
                  theme: theme,
                  title: 'Font size',
                  value: current.fontSize,
                  min: ReaderSettings.kMinFontSize,
                  max: ReaderSettings.kMaxFontSize,
                  divisions:
                      ((ReaderSettings.kMaxFontSize -
                                  ReaderSettings.kMinFontSize) ~/
                              ReaderSettings.kFontSizeStep)
                          .toInt(),
                  label: '${current.fontSize.toStringAsFixed(0)} px',
                  onChanged: (v) => controller.updateReaderSettings(
                    current.copyWith(fontSize: v),
                  ),
                ),

                _sliderRow(
                  theme: theme,
                  title: 'Line height',
                  value: current.lineHeight,
                  min: 1.2,
                  max: 2.6,
                  divisions: 14,
                  label: current.lineHeight.toStringAsFixed(1),
                  onChanged: (v) => controller.updateReaderSettings(
                    current.copyWith(
                      lineHeight: double.parse(v.toStringAsFixed(1)),
                    ),
                  ),
                ),

                _sliderRow(
                  theme: theme,
                  title: 'Paragraph spacing',
                  value: current.paragraphSpacing,
                  min: 0.0,
                  max: 2.0,
                  divisions: 10,
                  label: '${current.paragraphSpacing.toStringAsFixed(1)} em',
                  onChanged: (v) => controller.updateReaderSettings(
                    current.copyWith(
                      paragraphSpacing: double.parse(v.toStringAsFixed(1)),
                    ),
                  ),
                ),

                _sliderRow(
                  theme: theme,
                  title: 'Content width',
                  value: current.contentWidthEm,
                  min: 30,
                  max: 54,
                  divisions: 24,
                  label: '${current.contentWidthEm.toStringAsFixed(0)} em',
                  onChanged: (v) => controller.updateReaderSettings(
                    current.copyWith(contentWidthEm: v),
                  ),
                ),

                chipRow(
                  'Text alignment',
                  const ['Left', 'Justify', 'Center'],
                  current.textAlign,
                  (label) => controller.updateReaderSettings(
                    current.copyWith(
                      textAlign: label == 'Justify'
                          ? 'justify'
                          : label.toLowerCase(),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => controller.updateReaderSettings(
                      settings.copyWith(
                        themeMode: ReaderThemeMode.system,
                        fontFamily: ReaderSettings.kDefaultFontFamily,
                        fontSize: ReaderSettings.kDefaultFontSize,
                        lineHeight: 1.8,
                        paragraphSpacing: 1.0,
                        contentWidthEm: 42.0,
                        textAlign: 'justify',
                      ),
                    ),
                    child: const Text('Reset defaults'),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );

    Get.bottomSheet(
      sheet,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _sliderRow({
    required ThemeData theme,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Expanded(
            child: M3ESlider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: label,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
