import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_spacing.dart';

/// Visual variants mapped to [M3EButtonStyle].
enum AppButtonVariant { filled, tonal, outlined, elevated, text }

/// App's button: M3E wrapper with variant, optional icon, full-width and a
/// built-in busy (spinner) state.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.onPressed,
    super.key,
    this.label,
    this.icon,
    this.variant = AppButtonVariant.filled,
    this.size = M3EButtonSize.sm,
    this.isFullWidth = false,
    this.isLoading = false,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final Widget? label;
  final Widget? icon;
  final AppButtonVariant variant;
  final M3EButtonSize size;
  final bool isFullWidth;
  final bool isLoading;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final style = switch (variant) {
      AppButtonVariant.filled => M3EButtonStyle.filled,
      AppButtonVariant.tonal => M3EButtonStyle.tonal,
      AppButtonVariant.outlined => M3EButtonStyle.outlined,
      AppButtonVariant.elevated => M3EButtonStyle.elevated,
      AppButtonVariant.text => M3EButtonStyle.text,
    };
    final enabled = onPressed != null && !isLoading;

    final VoidCallback? handlePress = enabled
        ? () {
            HapticFeedback.lightImpact();
            onPressed?.call();
          }
        : null;

    final Widget button;
    if (isLoading) {
      button = M3EButton(
        onPressed: null,
        style: style,
        size: size,
        tooltip: tooltip,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: M3EProgressIndicator.circular(size: 20),
            ),
            if (label case final Widget label?) ...[
              const SizedBox(width: AppSpacing.sm),
              label,
            ],
          ],
        ),
      );
    } else if (icon case final Widget icon?) {
      button = M3EButton.icon(
        icon: icon,
        label: label ?? const SizedBox.shrink(),
        style: style,
        size: size,
        tooltip: tooltip,
        onPressed: handlePress,
      );
    } else {
      button = M3EButton(
        onPressed: handlePress,
        style: style,
        size: size,
        tooltip: tooltip,
        child: label ?? const SizedBox.shrink(),
      );
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
