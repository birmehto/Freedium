import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/mirror_source.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../controllers/settings_controller.dart';

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
    // Three short modes fit one row, so the body needs no scrollbar.
    isContentScrollable: false,
    contentBuilder: (context) => Center(
      child: M3ESegmentedButton<String>(
        semanticLabel: 'Theme',
        segments: [
          for (final mode in modes)
            M3ESegment<String>(value: mode.value, label: mode.label),
        ],
        selected: {controller.themeMode.value},
        onSelectionChanged: (selected) {
          controller.setThemeMode(selected.first);
          AppDialog.close(context);
        },
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
    contentBuilder: (context) {
      final theme = Theme.of(context);
      final selected = controller.preferredMirror.value ?? '';

      // Taps land on the radio; arrow keys on the group — one shared handler
      // so both paths pin the mirror and dismiss.
      void select(String id) {
        controller.setPreferredMirror(id.isEmpty ? null : id);
        AppDialog.close(context);
      }

      // M3ERadio lays its label out in a non-flexible row, so a long mirror
      // URL would size the row past the dialog. Give the label the width the
      // dialog actually has left for it.
      return LayoutBuilder(
        builder: (context, constraints) {
          final radioTheme = M3ETheme.of(context).radioTheme;
          final slot = math.max(radioTheme.targetSize, radioTheme.hitSize);
          final labelWidth = math.max(
            0.0,
            constraints.maxWidth - slot - radioTheme.labelGap,
          );

          return M3ERadioGroup<String>(
            groupLabel: 'Preferred Mirror',
            groupValue: selected,
            onChanged: select,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, id, subtitle) in options)
                  M3ERadio<String>(
                    value: id,
                    groupValue: selected,
                    onChanged: select,
                    label: SizedBox(
                      width: labelWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: theme.textTheme.bodyLarge),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
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
