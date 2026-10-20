import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_settings_tile.dart';
import '../controllers/support_controller.dart';

/// Asks how the user would like to support Freedium.
///
/// The donation row is the point of the dialog, so it is a full-width row that
/// closes the dialog and then hands off to the browser, which takes over the
/// screen and should not stack behind an open sheet.
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
          'subscription. Buying a coffee keeps it running.',
        ),
        const SizedBox(height: AppSpacing.md),
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
