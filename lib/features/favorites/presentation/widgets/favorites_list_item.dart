import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/url_validator.dart';
import '../../../../shared/widgets/app_animations.dart';
import '../../domain/entities/favorite_article.dart';

class FavoritesListItem extends StatelessWidget {
  const FavoritesListItem({required this.item, this.onDelete, super.key});

  final FavoriteArticle item;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(item.url),
      direction: onDelete == null
          ? DismissDirection.none
          : DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: _buildDeleteBackground(theme),
      child: TapScale(
        onTap: _openArticle,
        child: M3ECard(
          variant: M3ECardVariant.outlined,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _icon(theme.colorScheme),
                const SizedBox(width: 20),
                Expanded(child: _text(theme, theme.colorScheme)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openArticle() {
    final url = item.url;
    final freedium = UrlValidator.convertToFreediumUrl(url) ?? url;

    Get.toNamed(
      AppRoutes.article,
      arguments: {'url': freedium, 'originalUrl': url},
    );
  }

  Widget _buildDeleteBackground(ThemeData theme) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: .85),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(
        Icons.delete_sweep_rounded,
        color: theme.colorScheme.onErrorContainer,
        size: 28,
      ),
    );
  }

  Widget _icon(ColorScheme c) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: c.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.auto_stories_rounded, color: c.primary, size: 32),
    );
  }

  Widget _text(ThemeData theme, ColorScheme c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.domain != null || item.author != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              [item.author].whereType<String>().join(' • ').toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: c.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                fontSize: 10,
              ),
            ),
          ),
        Text(
          item.title.isNotEmpty ? item.title : 'Untitled Article',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 12,
              color: c.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat.yMMMd().add_jm().format(item.visitedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: c.onSurfaceVariant.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
