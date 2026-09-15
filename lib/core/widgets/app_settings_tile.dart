import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'app_icon_badge.dart';

/// Settings-style list item: icon badge leading, optional text trailing and a
/// chevron when [onTap] is provided.
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
    final c = Theme.of(context).colorScheme;

    return M3EListItem(
      headline: title,
      supportingText: supportingText,
      leading: icon != null
          ? AppIconBadge(
              icon: icon!,
              iconColor: iconColor ?? c.onSecondaryContainer,
              backgroundColor:
                  backgroundColor ?? c.primaryContainer.withValues(alpha: 0.6),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null ? const Icon(M3EIcons.chevron_right_rounded) : null),
      onTap: onTap,
    );
  }
}
