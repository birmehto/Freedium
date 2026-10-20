import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_spacing.dart';

/// A titled row of single-select [M3EChip]s.
class AppChoiceChips extends StatelessWidget {
  const AppChoiceChips({
    required this.title,
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.leadingBuilder,
    super.key,
  });

  final String title;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;

  /// Builds a chip's optional leading; a chip gets none by default.
  ///
  /// Lets a caller dress up the options (e.g. a color swatch next to the
  /// theme name) while keeping the single-select row behavior identical.
  final Widget Function(BuildContext context, String label)? leadingBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final label in labels)
              M3EChip(
                type: M3EChipType.filter,
                label: label,
                leading: leadingBuilder?.call(context, label),
                selected: selected == label,
                onPressed: () => onSelected(label),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
