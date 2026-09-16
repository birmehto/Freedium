import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import 'app_icon_badge.dart';

/// A settings-style list item with an optional icon, supporting text,
/// trailing widget, and navigation chevron.
class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    required this.title,
    super.key,
    this.icon,
    this.supportingText,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
  });

  final String title;
  final IconData? icon;
  final String? supportingText;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return M3EListItem(
      headline: title,
      supportingText: supportingText,
      leading: _buildLeading(colorScheme),
      trailing: _buildTrailing(),
      onTap: onTap,
    );
  }

  Widget? _buildLeading(ColorScheme colorScheme) {
    final icon = this.icon;
    if (icon == null) return null;

    return AppIconBadge(
      icon: icon,
      iconColor: iconColor ?? colorScheme.onSecondaryContainer,
      backgroundColor:
          backgroundColor ??
          colorScheme.primaryContainer.withValues(alpha: 0.6),
    );
  }

  Widget? _buildTrailing() {
    if (trailing != null) return trailing;

    return onTap != null ? const Icon(M3EIcons.chevron_right_rounded) : null;
  }
}
