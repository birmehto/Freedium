import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A titled row of single-select [ChoiceChip]s.
class AppChoiceChips extends StatelessWidget {
  const AppChoiceChips({
    required this.title,
    required this.labels,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String title;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in labels)
              ChoiceChip(
                label: Text(label),
                selected: selected == label,
                onSelected: (_) => onSelected(label),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
