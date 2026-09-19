import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_pill.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_settings_tile.dart';
import '../controllers/settings_controller.dart';
import '../widgets/font_size_sheet.dart';
import '../widgets/reader_appearance_sheet.dart';
import '../widgets/settings_dialogs.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

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
                    onTap: () => showThemeDialog(context),
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
                    onTap: () => showReaderAppearanceSheet(context),
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
                  onTap: () => showFontSizeSheet(context),
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
                    onTap: () => showMirrorDialog(context),
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
                        '${controller.savedCount.value} articles • '
                        '${controller.savedSizeLabel}',
                    icon: M3EIcons.download_rounded,
                    iconColor: c.onSecondaryContainer,
                    backgroundColor: c.secondaryContainer.withValues(
                      alpha: 0.6,
                    ),
                    onTap: controller.savedCount.value > 0
                        ? () => showClearSavedDialog(context)
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
                        '${controller.completedCount.value} finished • '
                        '${controller.readingMinutes.value} min read',
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
                  onTap: () => showCreditsDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
