import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/config/mirror_source.dart';
import '../../../core/theme/app_spacing.dart';
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

void showOfflineCacheDialog(BuildContext context) {
  final controller = Get.find<SettingsController>();

  // The dialog is about to be dismissed, and a context inside it cannot host a
  // snackbar afterwards. The page's own context outlives the dialog.
  final host = context;

  // Set synchronously on the first tap. The button's own busy state is only
  // rebuilt on the next frame, which is late enough for a fast double tap to
  // land on a still-enabled button and pop a second route.
  var clearing = false;

  AppDialog.show<void>(
    context,
    title: 'Offline Articles',
    contentBuilder: (context) => Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Articles are saved as you read them so they open without a '
            'connection. This device is holding '
            '${controller.offlineSummary.toLowerCase()}, and the oldest are '
            'cleared automatically once the cache grows too large.',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!controller.hasOfflineArticles)
            const Text('Nothing is saved yet.')
          else
            AppButton(
              variant: AppButtonVariant.tonal,
              icon: const Icon(M3EIcons.delete_sweep_rounded),
              // Disabled while the clear is running: the pop below only makes
              // sense once, and a second tap would pop the page behind it.
              isLoading: controller.isClearingCache.value,
              onPressed: () async {
                if (clearing) return;
                clearing = true;

                await controller.clearOfflineArticles();
                if (!context.mounted) return;
                AppDialog.close(context);

                M3ESnackbar.show(host, message: 'Offline articles cleared');
              },
              label: const Text('Clear saved articles'),
            ),
        ],
      ),
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
