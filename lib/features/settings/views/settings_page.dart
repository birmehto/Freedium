import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/mirror_source.dart';
import '../../../core/controllers/app_controllers.dart';
import '../../../core/theme/app_theme.dart';
import '../../support/widgets/support_dialog.dart';
import '../controllers/settings_controller.dart';
import '../widgets/reader_appearance_sheet.dart';
import '../widgets/settings_dialogs.dart';

/// Grouped rows under quiet uppercase labels — no elevated cards.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final theme = ref.watch(themeControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final muted = AppTheme.muted(context);

    final mirrorId = settings.preferredMirror;
    final mirrorName = mirrorId == null
        ? 'Auto'
        : MirrorCatalog.createDefaults()
              .where((mirror) => mirror.id == mirrorId)
              .map((mirror) => mirror.name)
              .firstWhere((_) => true, orElse: () => mirrorId);

    return Scaffold(
      backgroundColor: AppTheme.paper(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
          children: [
            Text(
              'Settings',
              style: GoogleFonts.sourceSerif4(
                fontSize: 38,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink(context),
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 32),

            const _SectionLabel('APPEARANCE'),
            _SettingsRow(
              title: 'Dark Mode',
              subtitle: 'Comfortable reading in low light',
              trailing: Switch(
                value: theme.isDarkMode,
                onChanged: controller.toggleTheme,
              ),
            ),
            const _Hairline(),
            _SettingsRow(
              title: 'Reader Appearance',
              subtitle: 'Theme, font family and text size used in the reader',
              onTap: () => showReaderAppearanceSheet(context),
              trailing: Icon(LucideIcons.chevronRight, size: 18, color: muted),
            ),

            const SizedBox(height: 32),
            const _SectionLabel('SOURCE'),
            _SettingsRow(
              title: 'Preferred Mirror',
              subtitle: mirrorName,
              onTap: () => showMirrorDialog(context),
              trailing: Icon(LucideIcons.chevronRight, size: 18, color: muted),
            ),
            const _Hairline(),
            _SettingsRow(
              title: 'Automatic Fallback',
              subtitle: 'Switch to another source when a mirror fails',
              trailing: Switch(
                value: settings.autoFallback,
                onChanged: controller.setAutoFallback,
              ),
            ),

            const SizedBox(height: 32),
            const _SectionLabel('ABOUT'),
            _SettingsRow(
              title: 'Support Freedium',
              subtitle: 'Keep the app free and ad-free',
              onTap: () => showSupportDialog(context),
              trailing: Icon(LucideIcons.coffee, size: 18, color: muted),
            ),
            const _Hairline(),
            _SettingsRow(
              title: 'Send Feedback',
              onTap: controller.sendFeedback,
            ),
            const _Hairline(),
            _SettingsRow(
              title: 'GitHub',
              subtitle: 'View the Freedium source code',
              onTap: controller.openGitHub,
            ),
            const _Hairline(),
            _SettingsRow(
              title: 'Version',
              trailing: Text(
                settings.appVersion,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: muted),
              ),
            ),
            const _Hairline(),
            _SettingsRow(
              title: 'Licenses & Credits',
              subtitle: 'The tiny legal bit',
              onTap: () => showCreditsDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: AppTheme.muted(context), letterSpacing: 1.6),
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: AppTheme.rule(context));
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = AppTheme.ink(context);

    return InkResponse(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: ink),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.muted(context)),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
