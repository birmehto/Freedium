import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../models/favorite_article.dart';

/// Asks before an article leaves the library.
///
/// Removing a favorite is a swipe away by design, which is exactly why it is
/// worth one confirmation: a saved article is the only copy the user controls,
/// and there is no undo. Returns true only when the user chose to remove it.
Future<bool> showDeleteFavoriteDialog(
  BuildContext context,
  FavoriteArticle article,
) async {
  final colors = context.colors;
  final name = article.title.trim().isEmpty
      ? article.domain ?? 'this article'
      : article.title.trim();

  final confirmed = await AppDialog.show<bool>(
    context,
    title: 'Remove from library?',
    icon: Icon(M3EIcons.delete_outline_rounded, color: colors.error),
    content: Text('"$name" will be removed from your library.'),
    actions: [
      AppButton(
        variant: AppButtonVariant.text,
        onPressed: () => AppDialog.close(context, false),
        label: const Text('Keep'),
      ),
      AppButton(
        onPressed: () => AppDialog.close(context, true),
        label: const Text('Remove'),
      ),
    ],
  );

  return confirmed ?? false;
}
