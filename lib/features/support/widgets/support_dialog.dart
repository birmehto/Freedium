import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/services/ad_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_settings_tile.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../controllers/support_controller.dart';
import 'ad_unavailable_dialog.dart';

/// Asks how the user would like to support Freedium.
///
/// The two options — a rewarded video and a one-off donation — are the whole
/// point of the dialog, so each is a full-width row that closes the dialog and
/// then hands off: the ad player and the browser both take over the screen, and
/// neither should stack behind an open sheet.
///
/// The ad row shows progress while the request is in flight but says nothing
/// about whether an ad will arrive — the answer comes only once the user picks
/// it, as either the video or [showAdUnavailableDialog]. The request itself is
/// started at app startup, so opening this sheet never has to wait.
void showSupportDialog(
  BuildContext context, {
  required SupportController controller,
}) {
  AppDialog.show<void>(
    context,
    title: 'Support Freedium',
    icon: const Icon(M3EIcons.volunteer_activism_rounded),
    contentBuilder: (dialogContext) => Obx(() {
      final loading = controller.adLoading;

      return Column(
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
            supportingText: loading
                ? 'Preparing an ad…'
                : 'Play a rewarded video',
            icon: M3EIcons.play_circle_rounded,
            // Waiting on the network: show progress and hold the row so a tap
            // cannot land before there is an ad to present.
            enabled: !loading,
            trailing: loading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: () => _watchAd(context, dialogContext, controller),
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
      );
    }),
    actions: [
      AppButton(
        variant: AppButtonVariant.text,
        onPressed: () => AppDialog.close(context),
        label: const Text('Maybe later'),
      ),
    ],
  );
}

/// Closes the sheet, plays the ad, and reports the result on the page behind it.
///
/// Runs against the page [context] rather than the dialog's, because the dialog
/// is gone by the time the ad finishes and its context is no longer mounted.
Future<void> _watchAd(
  BuildContext context,
  BuildContext dialogContext,
  SupportController controller,
) async {
  AppDialog.close(dialogContext);

  final outcome = await controller.watchAd();
  if (!context.mounted) return;

  switch (outcome) {
    case RewardedAdOutcome.earnedReward:
      AppSnackbar.show(context, message: 'Thank you for supporting Freedium!');
    case RewardedAdOutcome.unavailable:
      showAdUnavailableDialog(
        context,
        reason: controller.adFailureReason,
        controller: controller,
      );
    case RewardedAdOutcome.dismissed:
      // Closed early: nothing earned, and nothing worth saying.
      break;
  }
}
