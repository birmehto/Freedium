import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/support_controller.dart';

/// Displays the support dialog with options to rate the app or donate.
void showSupportDialog(BuildContext context) {
  final container = ProviderScope.containerOf(context);
  final controller = container.read(supportControllerProvider);
  final settings = container.read(settingsControllerProvider.notifier);

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
        'Freedium is free, ad-free, and has exactly zero pop-ups asking for '
        'your credit card.\n\n'
        'If it just rescued you from a paywall, a coffee keeps the developer '
        'awake and a rating tells other readers where to look. Pick whichever '
        'feels right.',
        style: Theme.of(dialogContext).textTheme.bodyMedium
            ?.copyWith(color: AppTheme.muted(dialogContext), height: 1.5),
      ),
      actions: [
        SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  unawaited(controller.buyCoffee());
                },
                icon: const Icon(LucideIcons.coffee, size: 18),
                label: const Text('Buy me a coffee'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.ink(dialogContext),
                  foregroundColor: AppTheme.paper(dialogContext),
                  elevation: 0,
                  shape: const RoundedRectangleBorder(),
                ),
              ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  unawaited(settings.rateApp());
                },
                icon: const Icon(LucideIcons.star, size: 18),
                label: const Text('Rate us'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.ink(dialogContext),
                  side: BorderSide(color: AppTheme.rule(dialogContext)),
                  shape: const RoundedRectangleBorder(),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.muted(dialogContext),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Not now, I’m reading'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
