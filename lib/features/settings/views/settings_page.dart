import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_pill.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_settings_tile.dart';
import '../controllers/settings_controller.dart';

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
              () => AppSettingsTile(
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
                  onPressed: () {
                    controller.setFontSize(AppConstants.defaultFontSize);
                  },
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
