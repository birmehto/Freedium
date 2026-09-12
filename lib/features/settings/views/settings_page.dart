import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

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
