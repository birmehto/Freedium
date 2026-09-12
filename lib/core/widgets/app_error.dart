import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// Centered error state with an optional retry and secondary action.
class AppError extends StatelessWidget {
  const AppError({
    required this.message,
    super.key,
    this.title = 'Something went wrong',
    this.icon = M3EIcons.error_outline_rounded,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.secondaryLabel,
    this.onSecondary,
    this.hint,
  });

  final String title;
  final String message;
  final IconData icon;

  final VoidCallback? onRetry;
  final String retryLabel;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: c.error),
            const SizedBox(height: 20),

            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: c.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: c.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            if (onRetry != null)
              SizedBox(
                width: double.infinity,
                child: M3EButton(
                  onPressed: onRetry,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(M3EIcons.refresh_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(retryLabel),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            if (secondaryLabel != null && onSecondary != null)
              SizedBox(
                width: double.infinity,
                child: M3EButton(
                  style: M3EButtonStyle.outlined,
                  onPressed: onSecondary,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(M3EIcons.open_in_browser_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(secondaryLabel!),
                    ],
                  ),
                ),
              ),

            if (hint != null) ...[
              const SizedBox(height: 20),
              Text(
                hint!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: c.onSurfaceVariant.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
