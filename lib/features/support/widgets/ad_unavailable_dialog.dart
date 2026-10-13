import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/services/ad_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../controllers/support_controller.dart';

/// Explains why the ad the user asked for could not play, and hands them the
/// donation instead of leaving them at a dead end.
///
/// Raised only after the user chooses the ad, so the support dialog itself
/// stays a simple two-option sheet and the explanation arrives exactly when the
/// user is wondering why nothing happened. The wording follows
/// [AdFailureReason], so a blocked device and an empty inventory do not get the
/// same generic line.
void showAdUnavailableDialog(
  BuildContext context, {
  required AdFailureReason reason,
  required SupportController controller,
}) {
  final copy = _copyFor(reason);

  AppDialog.show<void>(
    context,
    title: copy.title,
    icon: Icon(copy.icon),
    content: Text(copy.message),
    actions: [
      AppButton(
        variant: AppButtonVariant.text,
        onPressed: () => AppDialog.close(context),
        label: const Text('Close'),
      ),
      AppButton(
        onPressed: () {
          AppDialog.close(context);
          controller.buyCoffee();
        },
        label: const Text('Buy me a coffee'),
      ),
    ],
  );
}

/// The title, icon and body for each way an ad can fail to arrive.
({String title, IconData icon, String message}) _copyFor(
  AdFailureReason reason,
) {
  return switch (reason) {
    AdFailureReason.noConnection => (
      title: 'Ads are blocked',
      icon: M3EIcons.wifi_off_rounded,
      message:
          'Freedium could not reach the ad server. Check your internet '
          'connection, or an ad blocker or private DNS (like AdGuard) may be '
          'blocking ads. You can still support Freedium by buying a coffee.',
    ),
    AdFailureReason.noFill => (
      title: 'No ad available',
      icon: M3EIcons.sentiment_dissatisfied_rounded,
      message: 'No ad is available right now. Please try again in a moment.',
    ),
    AdFailureReason.invalidRequest => (
      title: 'Ads are not set up',
      icon: M3EIcons.error_outline_rounded,
      message:
          'Ads are not configured correctly right now. You can still support '
          'Freedium by buying a coffee.',
    ),
    AdFailureReason.timeout => (
      title: 'The ad took too long',
      icon: M3EIcons.hourglass_empty_rounded,
      message: 'The ad took too long to load. Please try again.',
    ),
    AdFailureReason.serverError => (
      title: 'Something went wrong',
      icon: M3EIcons.cloud_off_rounded,
      message: 'The ad server had a problem. Please try again in a moment.',
    ),
    AdFailureReason.unsupported => (
      title: 'Ads are not available',
      icon: M3EIcons.sentiment_dissatisfied_rounded,
      message:
          'Ads are not available on this device. You can still support '
          'Freedium by buying a coffee.',
    ),
    AdFailureReason.unknown => (
      title: 'No ad available',
      icon: M3EIcons.sentiment_dissatisfied_rounded,
      message: 'No ad could be loaded right now. Please try again in a moment.',
    ),
  };
}
