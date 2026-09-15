import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_icon_badge.dart';
import '../models/favorite_article.dart';

class FavoriteTile extends StatelessWidget {
  const FavoriteTile({required this.item, super.key});

  final FavoriteArticle item;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    final meta = <String?>[
      item.author,
      item.domain,
      DateFormat.yMMMd().add_jm().format(item.visitedAt),
    ].whereType<String>().join(' • ');

    return M3EListItem(
      headline: item.title.isNotEmpty ? item.title : 'Untitled Article',
      supportingText: meta,
      leading: AppIconBadge(
        icon: M3EIcons.auto_stories_rounded,
        size: 48,
        iconSize: 26,
        iconColor: c.primary,
      ),
      trailing: const Icon(M3EIcons.chevron_right_rounded),
    );
  }
}
