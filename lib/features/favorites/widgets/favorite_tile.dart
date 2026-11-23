import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../models/favorite_article.dart';

/// A saved article row: a serif title over a single quiet metadata line.
///
/// Deliberately plain — the list supplies the hairline separators and the
/// [Dismissible] supplies the swipe, so a tile is just the content and a
/// trailing delete control.
class FavoriteTile extends StatelessWidget {
  const FavoriteTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final FavoriteArticle item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ink = AppTheme.ink(context);
    final muted = AppTheme.muted(context);

    return InkResponse(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title.trim().isEmpty ? 'Untitled Article' : item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sourceSerif4(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _meta(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(LucideIcons.trash2, size: 18, color: muted),
              tooltip: 'Remove from library',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  /// Built once: constructing a `DateFormat` is locale-aware work, and a tile
  /// rebuilds on every scroll frame.
  static final DateFormat _dateFormat = DateFormat.yMMMd();

  static String _meta(FavoriteArticle item) => <String?>[
    item.author,
    item.domain,
    _dateFormat.format(item.visitedAt),
  ].whereType<String>().join(' · ');
}
