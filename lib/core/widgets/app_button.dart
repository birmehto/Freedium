import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

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
              child: M3EProgressIndicator.circularWavy(size: 18),
            ),
            if (label case final Widget label?) ...[
              const SizedBox(width: 8),
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
        onPressed: enabled ? onPressed : null,
      );
    } else {
      button = M3EButton(
        onPressed: enabled ? onPressed : null,
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
