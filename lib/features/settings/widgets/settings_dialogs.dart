import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/config/mirror_source.dart';
import '../../../core/widgets/app_button.dart';
import '../controllers/settings_controller.dart';
import 'settings_option_tile.dart';

void showThemeDialog(BuildContext context) {
  final controller = Get.find<SettingsController>();

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
              SettingsOptionTile(
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

void showMirrorDialog(BuildContext context) {
  final controller = Get.find<SettingsController>();

  final options = <(String, String, String?)>[
    ('Auto', '', 'Let Freedium choose'),
    for (final mirror in MirrorCatalog.createDefaults())
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
              SettingsOptionTile(
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

void showCreditsDialog(BuildContext context) {
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
