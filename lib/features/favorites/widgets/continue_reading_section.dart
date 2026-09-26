import 'dart:async';

import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_section_header.dart';
import '../models/continue_reading_item.dart';

/// "Continue reading" list shown above the saved articles.
///
/// Answers the question the favorites list cannot: not *what did I keep* but
/// *what was I in the middle of*.
class ContinueReadingSection extends StatelessWidget {
  const ContinueReadingSection({required this.items, super.key, this.onOpened});

  final List<ContinueReadingItem> items;

  /// Called after an article is opened and closed again.
  ///
  /// Reading moves the stored position, so the list is rebuilt on the way back
  /// rather than left showing where the reader was before they left it.
  final FutureOr<void> Function()? onOpened;

  /// A short list, so it cannot push the library itself off the screen.
  static const int _maxShown = 3;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(
          title: 'Continue reading',
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
        ),
        for (final item in items.take(_maxShown))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ContinueReadingTile(item: item, onOpened: onOpened),
          ),
      ],
    );
  }
}

class _ContinueReadingTile extends StatelessWidget {
  const _ContinueReadingTile({required this.item, this.onOpened});

  final ContinueReadingItem item;
  final FutureOr<void> Function()? onOpened;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final meta = <String?>[
      item.author,
      item.domain,
      if (item.percent > 0) '${item.percent}% read',
    ].whereType<String>().join(' • ');

    return M3ECard(
      variant: M3ECardVariant.outlined,
      onPressed: () async {
        await Get.toNamed(
          AppRoutes.article,
          arguments: {'url': item.url, 'originalUrl': item.url},
        );
        await onOpened?.call();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(M3EIcons.menu_book_rounded, size: 20, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.displayTitle,
                  style: context.text.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              meta,
              style: context.text.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          M3EProgressIndicator.linear(
            value: item.ratio.clamp(0.0, 1.0),
            color: colors.primary,
            semanticsLabel: 'Reading progress',
            semanticsValue: '${item.percent}%',
          ),
        ],
      ),
    );
  }
}
