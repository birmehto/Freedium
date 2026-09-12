import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_icon_badge.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const SizedBox(height: 12),
        _sectionHeader(context, 'Appearance'),
        M3ECard(
          variant: M3ECardVariant.filled,
          child: Obx(
            () => M3EListItem(
              headline: 'Dark Mode',
              supportingText: 'Comfortable reading in low light',
              leading: _iconBadge(
                c.primaryContainer,
                controller.isDarkMode
                    ? M3EIcons.dark_mode_rounded
                    : M3EIcons.light_mode_rounded,
                c.onSecondaryContainer,
              ),
              trailing: M3ESwitch(
                value: controller.isDarkMode,
                onChanged: controller.toggleTheme,
              ),
            ),
          ),
        ),
        _sectionHeader(context, 'About'),
        M3ECard(
          variant: M3ECardVariant.filled,
          child: Column(
            children: [
              M3EListItem(
                headline: 'Send Feedback',
                leading: _iconBadge(
                  c.tertiaryContainer,
                  M3EIcons.mail_outline_rounded,
                  c.onTertiaryContainer,
                ),
                trailing: const Icon(M3EIcons.chevron_right_rounded),
                onTap: controller.sendFeedback,
              ),
              const M3EDivider(),
              M3EListItem(
                headline: 'Version',
                leading: _iconBadge(
                  c.secondaryContainer,
                  M3EIcons.info_outline_rounded,
                  c.onSecondaryContainer,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: c.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: c.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    controller.appVersion.value,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: c.primary,
                    ),
                  ),
                ),
              ),
              const M3EDivider(),
              M3EListItem(
                headline: 'Licenses & Credits',
                leading: _iconBadge(
                  c.secondaryContainer,
                  M3EIcons.gavel_rounded,
                  c.onSecondaryContainer,
                ),
                onTap: () => _showCreditsDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _iconBadge(Color bg, IconData icon, Color iconColor) {
    return AppIconBadge(
      icon: icon,
      iconColor: iconColor,
      backgroundColor: bg.withValues(alpha: 0.6),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
          color: theme.colorScheme.primary.withValues(alpha: 0.85),
        ),
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
            'Readora is not affiliated with Medium.\n\n'
            'All article content belongs to their respective authors.',
          ),
          actions: [
            M3EButton(
              style: M3EButtonStyle.text,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
