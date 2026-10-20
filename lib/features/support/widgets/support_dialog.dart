import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../controllers/support_controller.dart';

/// Displays the support dialog with an option to donate via browser.
void showSupportDialog(
  BuildContext context, {
  required SupportController controller,
}) {
  AppDialog.show<void>(
    context,
    title: 'Support Freedium',
    icon: const Icon(M3EIcons.volunteer_activism_rounded),
    content: const Text(
      'Freedium is free, open source, and ad-free. If you enjoy reading clutter-free '
      'articles, consider buying a coffee to support development and keep the app running!',
    ),
    actions: [
      AppButton(
        variant: AppButtonVariant.text,
        onPressed: () => AppDialog.close(context),
        label: const Text('Maybe later'),
      ),
      AppButton(
        icon: const Icon(M3EIcons.coffee_rounded),
        onPressed: () {
          AppDialog.close(context);
          controller.buyCoffee();
        },
        label: const Text('Buy me a coffee'),
      ),
    ],
  );
}
