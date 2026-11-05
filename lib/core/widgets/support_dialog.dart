import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../utils/url_launcher.dart';
import 'app_button.dart';
import 'app_dialog.dart';

/// Displays the support dialog with an option to donate via browser.
void showSupportDialog(BuildContext context) {
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
          launchSupportUrl();
        },
        label: const Text('Buy me a coffee'),
      ),
    ],
  );
}