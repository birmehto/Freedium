import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/favorites_controller.dart';

/// Asks before an article leaves the library, then removes it.
///
/// Removing a favorite is a swipe away by design, which is exactly why it is
/// worth one confirmation: a saved article is the only copy the user controls,
/// and there is no undo. Returns true only when the user chose to remove it.
Future<bool> showDeleteFavoriteDialog(
  BuildContext context, {
  required String url,
  required String title,
}) async {
  final name = title.trim().isEmpty ? url : title.trim();
  final notifier = ProviderScope.containerOf(context)
      .read(favoritesControllerProvider.notifier);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.paper(dialogContext),
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Remove from library?',
        style: Theme.of(dialogContext).textTheme.titleLarge
            ?.copyWith(color: AppTheme.ink(dialogContext)),
      ),
      content: Text(
        '“$name” will be removed from your library.',
        style: Theme.of(dialogContext).textTheme.bodyMedium
            ?.copyWith(color: AppTheme.muted(dialogContext)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;

  await notifier.removeFavorite(url);
  return true;
}
