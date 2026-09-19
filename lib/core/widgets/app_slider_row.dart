import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// A labeled [M3ESlider] row with the value shown next to the label.
class AppSliderRow extends StatelessWidget {
  const AppSliderRow({
    required this.title,
    required this.value,
    required this.label,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    super.key,
  });

  final String title;
  final double value;
  final String label;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Expanded(
            child: M3ESlider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: label,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
