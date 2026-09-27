import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/mirror_source.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../controllers/settings_controller.dart';
import 'settings_option_tile.dart';

void showThemeDialog(BuildContext context) {
  final controller = Get.find<SettingsController>();

  const modes = [
    (label: 'System', value: 'system'),
    (label: 'Light', value: 'light'),
    (label: 'Dark', value: 'dark'),
  ];

  AppDialog.show<void>(
    context,
    title: 'Theme',
    contentBuilder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final mode in modes)
          SettingsOptionTile(
            label: mode.label,
            selected: controller.themeMode.value == mode.value,
            onTap: () {
              controller.setThemeMode(mode.value);
              AppDialog.close(context);
            },
          ),
      ],
    ),
    actions: [
      AppButton(
        variant: AppButtonVariant.text,
        onPressed: () => AppDialog.close(context),
        label: const Text('Close'),
      ),
    ],
  );
}

void showMirrorDialog(BuildContext context) {
  final controller = Get.find<SettingsController>();

  final options = <(String, String, String?)>[
    ('Auto', '', 'Let Freedium choose'),
    for (final mirror in MirrorCatalog.createDefaults())
      (mirror.name, mirror.id, mirror.url),
  ];

  AppDialog.show<void>(
    context,
    title: 'Preferred Mirror',
    contentBuilder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (label, id, subtitle) in options)
          SettingsOptionTile(
            label: label,
            subtitle: subtitle,
            selected: (controller.preferredMirror.value ?? '') == id,
            onTap: () {
              controller.setPreferredMirror(id.isEmpty ? null : id);
              AppDialog.close(context);
            },
          ),
      ],
    ),
    actions: [
      AppButton(
        variant: AppButtonVariant.text,
        onPressed: () => AppDialog.close(context),
        label: const Text('Close'),
      ),
    ],
  );
}

void showCreditsDialog(BuildContext context) {
  AppDialog.show<void>(
    context,
    title: 'Licenses & Credits',
    content: const Text(
      'Freedium is not affiliated with Medium.\n\n'
      'All article content belongs to their respective authors.',
    ),
    actions: [
      AppButton(
        variant: AppButtonVariant.text,
        onPressed: () => AppDialog.close(context),
        label: const Text('Close'),
      ),
    ],
  );
}
