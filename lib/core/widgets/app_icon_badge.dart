import 'package:material_ui/material_ui.dart';

import '../theme/app_spacing.dart';

/// Rounded container that frames an icon (list leading, settings tiles...).
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    required this.icon,
    super.key,
    this.iconColor,
    this.iconSize = 22,
    this.backgroundColor,
    this.size,
    this.padding,
  });

  final IconData icon;
  final Color? iconColor;
  final double iconSize;
  final Color? backgroundColor;
  final double? size;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    final decoration = BoxDecoration(
      color: backgroundColor ?? c.primaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    final content = Icon(
      icon,
      size: iconSize,
      color: iconColor ?? c.onSecondaryContainer,
    );

    if (size != null) {
      return Container(
        width: size,
        height: size,
        decoration: decoration,
        child: Center(child: content),
      );
    }
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: decoration,
      child: content,
    );
  }
}
