import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/mirror_source.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/settings_controller.dart';

void showThemeDialog(BuildContext context) {
  final container = ProviderScope.containerOf(context);
  final controller = container.read(settingsControllerProvider.notifier);
  final current = container.read(settingsControllerProvider).themeMode;

  const modes = [('System', 'system'), ('Light', 'light'), ('Dark', 'dark')];

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.paper(dialogContext),
      surfaceTintColor: Colors.transparent,
      title: _dialogTitle(dialogContext, 'Theme'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < modes.length; i++) ...[
            _DialogOption(
              label: modes[i].$1,
              selected: current == modes[i].$2,
              onTap: () {
                controller.setThemeMode(modes[i].$2);
                Navigator.of(dialogContext).pop();
              },
            ),
            if (i < modes.length - 1)
              Divider(height: 1, color: AppTheme.rule(dialogContext)),
          ],
        ],
      ),
    ),
  );
}

void showMirrorDialog(BuildContext context) {
  final container = ProviderScope.containerOf(context);
  final controller = container.read(settingsControllerProvider.notifier);
  final selected =
      container.read(settingsControllerProvider).preferredMirror ?? '';

  final options = <(String, String, String?)>[
    ('Auto', '', 'Let Freedium choose'),
    for (final mirror in MirrorCatalog.createDefaults())
      (mirror.name, mirror.id, mirror.url),
  ];

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.paper(dialogContext),
      surfaceTintColor: Colors.transparent,
      title: _dialogTitle(dialogContext, 'Preferred Mirror'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < options.length; i++) ...[
              _DialogOption(
                label: options[i].$1,
                subtitle: options[i].$3,
                selected: selected == options[i].$2,
                onTap: () {
                  final id = options[i].$2;
                  controller.setPreferredMirror(id.isEmpty ? null : id);
                  Navigator.of(dialogContext).pop();
                },
              ),
              if (i < options.length - 1)
                Divider(height: 1, color: AppTheme.rule(dialogContext)),
            ],
          ],
        ),
      ),
    ),
  );
}

void showCreditsDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.paper(dialogContext),
      surfaceTintColor: Colors.transparent,
      title: _dialogTitle(dialogContext, 'Licenses & Credits'),
      content: Text(
        'Freedium is an independent reader built by Bir.\n\n'
        'It is not affiliated with Medium. Stories belong to their authors — '
        'we just help you read them.\n\n'
        'Thanks for reading.',
        style: Theme.of(dialogContext).textTheme.bodyMedium
            ?.copyWith(color: AppTheme.muted(dialogContext), height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Widget _dialogTitle(BuildContext context, String text) => Text(
  text,
  style: GoogleFonts.sourceSerif4(
    fontSize: 21,
    fontWeight: FontWeight.w600,
    color: AppTheme.ink(context),
  ),
);

class _DialogOption extends StatelessWidget {
  const _DialogOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ink = AppTheme.ink(context);
    final muted = AppTheme.muted(context);

    return InkResponse(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: ink),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: muted),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Icon(
                LucideIcons.check,
                size: 18,
                color: AppTheme.accent(context),
              ),
          ],
        ),
      ),
    );
  }
}
