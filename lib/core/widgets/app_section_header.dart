import 'package:material_ui/material_ui.dart';

import '../extensions/context_ext.dart';

/// Uppercase section label used to group settings/content sections.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    required this.title,
    super.key,
    this.padding = const EdgeInsets.fromLTRB(12, 28, 12, 12),
  });

  final String title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title.toUpperCase(),
        style: context.text.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
          color: context.colors.primary.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}