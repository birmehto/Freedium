import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_settings_tile.dart';
import '../controllers/support_controller.dart';

/// Asks how the user would like to support Freedium.
///
/// The two options — a rewarded video and a one-off donation — are the whole
/// point of the dialog, so each is a full-width row that closes the dialog and
/// then hands off: the ad player and the browser both take over the screen, and
/// neither should stack behind an open sheet.
void showSupportDialog(
  BuildContext context, {
  required SupportController controller,
}) {
  AppDialog.show<void>(
    context,
    title: 'Support Freedium',
    icon: const Icon(M3EIcons.volunteer_activism_rounded),
    contentBuilder: (dialogContext) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Freedium is free and open source, with no account and no '
          'subscription. Watching a short ad or buying a coffee keeps it '
          'running.',
        ),
        const SizedBox(height: AppSpacing.md),
        AppSettingsTile(
          title: 'Watch a short ad',
          supportingText: 'Play a rewarded video',
          icon: M3EIcons.play_circle_rounded,
          onTap: () {
            AppDialog.close(dialogContext);
            controller.watchAd();
          },
        ),
        const M3EDivider(),
        AppSettingsTile(
          title: 'Buy me a coffee',
          supportingText: 'One-off donation in the browser',
          icon: M3EIcons.coffee_rounded,
          onTap: () {
            AppDialog.close(dialogContext);
            controller.buyCoffee();
          },
        ),
      ],
    ),
    actions: [
      AppButton(
        variant: AppButtonVariant.text,
        onPressed: () => AppDialog.close(context),
        label: const Text('Maybe later'),
      ),
    ],
  );
}
