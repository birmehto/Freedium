import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/theme/app_spacing.dart';
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
    return Scaffold(
      appBar: const AppAppBar(title: Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
                    onTap: () => showThemeDialog(context),
                    trailing: const Icon(M3EIcons.chevron_right_rounded),
                  ),
                  const M3EDivider(),
                  AppSettingsTile(
                    title: 'Reader Appearance',
                    supportingText:
                        'Theme, font, spacing and alignment used in the reader',
                    icon: M3EIcons.auto_awesome_rounded,

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
            child: Obx(
              () => AppSettingsTile(
                title: 'Default Font Size',
                supportingText: '${controller.fontSize.toStringAsFixed(0)} px',
                icon: M3EIcons.format_size_rounded,

                onTap: () => showFontSizeSheet(context),
                trailing: const Icon(M3EIcons.chevron_right_rounded),
              ),
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

                    trailing: M3ESwitch(
                      value: controller.autoFallback.value,
                      onChanged: controller.setAutoFallback,
                    ),
                  ),
                ),
              ],
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

                  onTap: controller.sendFeedback,
                ),
                const M3EDivider(),
                AppSettingsTile(
                  title: 'GitHub',
                  supportingText: 'View the Freedium source code',
                  icon: M3EIcons.code_rounded,

                  onTap: controller.openGitHub,
                ),
                const M3EDivider(),
                AppSettingsTile(
                  title: 'Version',
                  icon: M3EIcons.info_outline_rounded,

                  trailing: Obx(
                    () => AppPill(label: controller.appVersion.value),
                  ),
                ),
                const M3EDivider(),
                AppSettingsTile(
                  title: 'Licenses & Credits',
                  icon: M3EIcons.gavel_rounded,

                  onTap: () => showCreditsDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}
