import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_icon_badge.dart';
import '../models/favorite_article.dart';

/// A saved article row.
///
/// Extends [M3EListItem] instead of wrapping it: a list row only swipes when
/// the widget the list builds *is* an [M3EListItem], so a wrapper would drop
/// the [swipe] passed in here without a word.
class FavoriteTile extends M3EListItem {
  FavoriteTile({required FavoriteArticle item, super.swipe, super.key})
    : super(
        headline: item.title.isNotEmpty ? item.title : 'Untitled Article',
        supportingText: _meta(item),
        leading: const Builder(builder: _badge),
        trailing: const Icon(M3EIcons.chevron_right_rounded),
      );

  static String _meta(FavoriteArticle item) => <String?>[
    item.author,
    item.domain,
    DateFormat.yMMMd().add_jm().format(item.visitedAt),
  ].whereType<String>().join(' • ');

  static Widget _badge(BuildContext context) => AppIconBadge(
    icon: M3EIcons.auto_stories_rounded,
    size: 48,
    iconSize: 26,
    iconColor: Theme.of(context).colorScheme.primary,
  );
}
