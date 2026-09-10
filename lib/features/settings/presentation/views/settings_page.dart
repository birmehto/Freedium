import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../shared/widgets/app_page.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return AppPage(
      title: 'Settings',
      padding: const EdgeInsets.symmetric(horizontal: 20),
      slivers: [
        const SizedBox(height: 12),
        _sectionHeader(context, 'Appearance'),
        M3ECard(
          variant: M3ECardVariant.filled,
          child: Obx(
            () => M3EListItem(
              headline: 'Dark Mode',
              supportingText: 'Comfortable reading in low light',
              leading: _iconBox(
                theme,
                controller.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                c.primaryContainer,
              ),
              trailing: M3ESwitch(
                value: controller.isDarkMode,
                onChanged: controller.toggleTheme,
              ),
            ),
          ),
        ),
        _sectionHeader(context, 'Reader Engine'),
        M3ECard(
          variant: M3ECardVariant.filled,
          child: Obx(
            () => M3EListItem(
              headline: 'Active Engine',
              supportingText: 'Alternative engine if primary fails',
              leading: _iconBox(
                theme,
                Icons.swap_horizontal_circle_rounded,
                c.secondaryContainer,
              ),
              trailing: M3EDropdownMenu<String>(
                singleSelect: true,
                items: StorageService.availableEngines
                    .map(
                      (engine) => M3EDropdownItem(
                        label: engine['name']!,
                        value: engine['url']!,
                      ),
                    )
                    .toList(),
                onSelectionChanged: (items) {
                  if (items.isNotEmpty) {
                    controller.setEngineUrl(items.first.value);
                  }
                },
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
                leading: _iconBox(
                  theme,
                  Icons.mail_outline_rounded,
                  c.tertiaryContainer,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: controller.sendFeedback,
              ),
              const M3EDivider(),
              M3EListItem(
                headline: 'Version',
                leading: _iconBox(
                  theme,
                  Icons.info_outline_rounded,
                  c.secondaryContainer,
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
                    '1.0.0',
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
                leading: _iconBox(
                  theme,
                  Icons.gavel_rounded,
                  c.secondaryContainer,
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

  Widget _iconBox(ThemeData theme, IconData icon, Color bg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        size: 22,
        color: theme.colorScheme.onSecondaryContainer,
      ),
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
      dialog: M3EDialog(
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
    );
  }
}
