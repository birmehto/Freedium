import 'package:material_ui/material_ui.dart';

import '../extensions/context_ext.dart';

/// Small rounded container that frames a short piece of text (version, tag).
class AppPill extends StatelessWidget {
  const AppPill({required this.label, super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: context.text.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: color ?? c.primary,
        ),
      ),
    );
  }
}
