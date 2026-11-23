import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/support_controller.dart';

/// Displays the support dialog with an option to donate via the browser.
void showSupportDialog(BuildContext context) {
  final controller = ProviderScope.containerOf(context)
      .read(supportControllerProvider);

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.paper(dialogContext),
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Support Freedium',
        style: GoogleFonts.sourceSerif4(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          color: AppTheme.ink(dialogContext),
        ),
      ),
      content: Text(
        'Freedium is free, open source, and ad-free. If you enjoy reading '
        'clutter-free articles, consider buying a coffee to support '
        'development and keep the app running!',
        style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
              color: AppTheme.muted(dialogContext),
              height: 1.5,
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Maybe later'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            unawaited(controller.buyCoffee());
          },
          child: const Text('Buy me a coffee'),
        ),
      ],
    ),
  );
}
