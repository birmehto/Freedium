import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/mirror_source.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_pill.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_settings_tile.dart';
import '../controllers/settings_controller.dart';
import '../models/reader_settings.dart';
import '../models/reader_theme_mode.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return Scaffold(
      appBar: const AppAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppSectionHeader(title: 'Appearance'),
          M3ECard(
            variant: M3ECardVariant.filled,
            child: Obx(
              () => Column(
                children: [
                  AppSettingsTile(
                    title: 'Dark Mode',
                    supportingText: 'Comfortable reading in low light',
                    icon: controller.isDarkMode
                        ? M3EIcons.dark_mode_rounded
                        : M3EIcons.light_mode_rounded,
                    trailing: M3ESwitch(
                      value: controller.isDarkMode,
                      onChanged: controller.toggleTheme,
                    ),
                  ),
                  const M3EDivider(),
                  AppSettingsTile(
                    title: 'Theme',
                    supportingText: controller.themeMode.value,
                    icon: M3EIcons.palette_rounded,
                    iconColor: c.onPrimaryContainer,
                    backgroundColor: c.primaryContainer.withValues(alpha: 0.6),
                    onTap: () => _showThemeDialog(context),
                    trailing: const Icon(M3EIcons.chevron_right_rounded),
                  ),
                  const M3EDivider(),
                  AppSettingsTile(
                    title: 'Reader Appearance',
                    supportingText:
                        'Theme, font, spacing and alignment used in the reader',
                    icon: M3EIcons.auto_awesome_rounded,
                    iconColor: c.onPrimaryContainer,
                    backgroundColor: c.primaryContainer.withValues(alpha: 0.6),
                    onTap: () => _showReaderAppearanceSheet(context),
                    trailing: const Icon(M3EIcons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
          ),

          const AppSectionHeader(title: 'Reader'),
          M3ECard(
            variant: M3ECardVariant.filled,
            child: Column(
              children: [
                AppSettingsTile(
                  title: 'Default Font Size',
                  supportingText:
                      '${controller.fontSize.value.toStringAsFixed(0)} px',
                  icon: M3EIcons.format_size_rounded,
                  iconColor: c.onPrimaryContainer,
                  backgroundColor: c.primaryContainer.withValues(alpha: 0.6),
                  onTap: () => _showFontSizeSheet(context),
                  trailing: const Icon(M3EIcons.chevron_right_rounded),
                ),
              ],
            ),
          ),

          const AppSectionHeader(title: 'Source'),
          M3ECard(
            variant: M3ECardVariant.filled,
            child: Column(
              children: [
                Obx(
                  () => AppSettingsTile(
                    title: 'Preferred Mirror',
                    supportingText: controller.preferredMirror.value ?? 'Auto',
                    icon: M3EIcons.swap_horiz_rounded,
                    iconColor: c.onTertiaryContainer,
                    backgroundColor: c.tertiaryContainer.withValues(alpha: 0.6),
                    onTap: () => _showMirrorDialog(context),
                    trailing: const Icon(M3EIcons.chevron_right_rounded),
                  ),
                ),
                const M3EDivider(),
                Obx(
                  () => AppSettingsTile(
                    title: 'Automatic Fallback',
                    supportingText:
                        'Switch to another source when a mirror fails',
                    icon: M3EIcons.autorenew_rounded,
                    iconColor: c.onTertiaryContainer,
                    backgroundColor: c.tertiaryContainer.withValues(alpha: 0.6),
                    trailing: M3ESwitch(
                      value: controller.autoFallback.value,
                      onChanged: controller.setAutoFallback,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const AppSectionHeader(title: 'Library & Storage'),
          M3ECard(
            variant: M3ECardVariant.filled,
            child: Obx(
              () => Column(
                children: [
                  AppSettingsTile(
                    title: 'Saved articles',
                    supportingText:
                        '${controller.savedCount.value} articles • ${controller.savedSizeLabel}',
                    icon: M3EIcons.download_rounded,
                    iconColor: c.onSecondaryContainer,
                    backgroundColor: c.secondaryContainer.withValues(
                      alpha: 0.6,
                    ),
                    onTap: controller.savedCount.value > 0
                        ? () => _confirmClearSaved(context)
                        : null,
                    trailing: controller.savedCount.value > 0
                        ? const Icon(M3EIcons.delete_rounded)
                        : null,
                  ),
                  const M3EDivider(),
                  AppSettingsTile(
                    title: 'Recent searches',
                    supportingText:
                        '${controller.recentSearchCount.value} saved',
                    icon: M3EIcons.search_rounded,
                    iconColor: c.onSecondaryContainer,
                    backgroundColor: c.secondaryContainer.withValues(
                      alpha: 0.6,
                    ),
                    onTap: controller.recentSearchCount.value > 0
                        ? controller.clearRecentSearches
                        : null,
                    trailing: controller.recentSearchCount.value > 0
                        ? const Icon(M3EIcons.delete_rounded)
                        : null,
                  ),
                  const M3EDivider(),
                  AppSettingsTile(
                    title: 'Reading statistics',
                    supportingText:
                        '${controller.completedCount.value} finished • ${controller.readingMinutes.value} min read',
                    icon: M3EIcons.insights_rounded,
                    iconColor: c.onSecondaryContainer,
                    backgroundColor: c.secondaryContainer.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const AppSectionHeader(title: 'About'),
          M3ECard(
            variant: M3ECardVariant.filled,
            child: Column(
              children: [
                AppSettingsTile(
                  title: 'Send Feedback',
                  icon: M3EIcons.mail_outline_rounded,
                  iconColor: c.onTertiaryContainer,
                  backgroundColor: c.tertiaryContainer.withValues(alpha: 0.6),
                  onTap: controller.sendFeedback,
                ),

                const M3EDivider(),
                AppSettingsTile(
                  title: 'GitHub',
                  supportingText: 'View the Freedium source code',
                  icon: M3EIcons.code_rounded,
                  iconColor: c.onTertiaryContainer,
                  backgroundColor: c.tertiaryContainer.withValues(alpha: 0.6),
                  onTap: controller.openGitHub,
                ),
                const M3EDivider(),
                AppSettingsTile(
                  title: 'Version',
                  icon: M3EIcons.info_outline_rounded,
                  iconColor: c.onSecondaryContainer,
                  backgroundColor: c.secondaryContainer.withValues(alpha: 0.6),
                  trailing: Obx(
                    () => AppPill(label: controller.appVersion.value),
                  ),
                ),
                const M3EDivider(),
                AppSettingsTile(
                  title: 'Licenses & Credits',
                  icon: M3EIcons.gavel_rounded,
                  iconColor: c.onSecondaryContainer,
                  backgroundColor: c.secondaryContainer.withValues(alpha: 0.6),
                  onTap: () => _showCreditsDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ─────────────────────────────── dialogs ────────────────────────────

  void _showThemeDialog(BuildContext context) {
    const modes = [
      (label: 'System', value: 'system'),
      (label: 'Light', value: 'light'),
      (label: 'Dark', value: 'dark'),
    ];

    M3EDialog.show<void>(
      context,
      dialog: Material(
        child: M3EDialog(
          title: 'Theme',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in modes)
                _optionTile(
                  context: context,
                  label: mode.label,
                  selected: controller.themeMode.value == mode.value,
                  onTap: () {
                    controller.setThemeMode(mode.value);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
          actions: [
            AppButton(
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(),
              label: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMirrorDialog(BuildContext context) {
    final options = <(String, String, String?)>[
      ('Auto', '', 'Let Freedium choose'),
      for (final mirror in MirrorCatalog.defaults)
        (mirror.name, mirror.id, mirror.url),
    ];

    M3EDialog.show<void>(
      context,
      dialog: Material(
        child: M3EDialog(
          title: 'Preferred Mirror',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (label, id, subtitle) in options)
                _optionTile(
                  context: context,
                  label: label,
                  subtitle: subtitle,
                  selected: (controller.preferredMirror.value ?? '') == id,
                  onTap: () {
                    controller.setPreferredMirror(id.isEmpty ? null : id);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
          actions: [
            AppButton(
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(),
              label: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyLarge),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              Icon(
                M3EIcons.check_circle_rounded,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  void _confirmClearSaved(BuildContext context) {
    M3EDialog.show<void>(
      context,
      dialog: Material(
        child: M3EDialog(
          title: 'Delete saved articles?',
          content: const Text(
            'This removes all articles saved for offline reading from this device.',
          ),
          actions: [
            AppButton(
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(),
              label: const Text('Cancel'),
            ),
            AppButton(
              onPressed: () {
                controller.clearSavedArticles();
                Navigator.of(context).pop();
              },
              label: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────── sheets ─────────────────────────────

  void _showFontSizeSheet(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    final sheet = Material(
      color: c.surfaceContainer,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              handle(theme),
              Text('Default Font Size', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Decrease font size',
                    onPressed: () =>
                        _adjustSize(context, -AppConstants.fontSizeStep),
                    icon: const Icon(M3EIcons.remove_rounded),
                  ),
                  Expanded(
                    child: Obx(
                      () => M3ESlider(
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
                    onPressed: () =>
                        _adjustSize(context, AppConstants.fontSizeStep),
                    icon: const Icon(M3EIcons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      controller.setFontSize(AppConstants.defaultFontSize),
                  child: const Text('Reset to default'),
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

  void _showReaderAppearanceSheet(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    final sheet = Material(
      color: c.surfaceContainer,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Obx(() {
            final current = controller.readerSettings.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                handle(theme),
                Text('Reader Appearance', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),

                chipRow(
                  theme: theme,
                  title: 'Theme',
                  labels: ReaderThemeMode.values.map((m) => m.label).toList(),
                  selected: current.themeMode.label,
                  onSelected: (label) => controller.updateReaderSettings(
                    current.copyWith(
                      themeMode: ReaderThemeMode.values.firstWhere(
                        (m) => m.label == label,
                      ),
                    ),
                  ),
                ),

                chipRow(
                  theme: theme,
                  title: 'Font family',
                  labels: const ['System', 'Georgia', 'Inter', 'Merriweather'],
                  selected: current.fontFamily,
                  onSelected: (label) => controller.updateReaderSettings(
                    current.copyWith(fontFamily: label),
                  ),
                ),

                sliderRow(
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

                sliderRow(
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

                sliderRow(
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
                  theme: theme,
                  title: 'Text alignment',
                  labels: const ['Left', 'Justify', 'Center'],
                  selected: current.textAlign,
                  onSelected: (label) => controller.updateReaderSettings(
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
                    onPressed: () =>
                        controller.updateReaderSettings(const ReaderSettings()),
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

  Widget handle(ThemeData theme) {
    final c = theme.colorScheme;
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: c.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget chipRow({
    required ThemeData theme,
    required String title,
    required List<String> labels,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
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

  Widget sliderRow({
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

  void _adjustSize(BuildContext context, double delta) {
    final next = controller.fontSize.value + delta;
    if (next >= AppConstants.minFontSize && next <= AppConstants.maxFontSize) {
      controller.setFontSize(next);
    }
  }

  void _showCreditsDialog(BuildContext context) {
    M3EDialog.show<void>(
      context,
      dialog: Material(
        child: M3EDialog(
          title: 'Licenses & Credits',
          content: const Text(
            'Freedium is not affiliated with Medium.\n\n'
            'All article content belongs to their respective authors.',
          ),
          actions: [
            AppButton(
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(),
              label: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
