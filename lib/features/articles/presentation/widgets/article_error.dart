import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../shared/widgets/app_animations.dart';

class ArticleError extends StatelessWidget {
  const ArticleError({
    required this.message,
    super.key,
    this.onRetry,
    this.onOpenBrowser,
    this.onSwitchEngine,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenBrowser;
  final VoidCallback? onSwitchEngine;

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
            const ScaleIn(child: Icon(Icons.error_outline_rounded, size: 64)),
            const SizedBox(height: 20),

            Text(
              'Failed to Load Article',
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Retry'),
                    ],
                  ),
                ),
              ),

            if (onSwitchEngine != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: M3EButton(
                  style: M3EButtonStyle.elevated,
                  onPressed: onSwitchEngine,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horizontal_circle_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Try Alternative Engine'),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            if (onOpenBrowser != null)
              SizedBox(
                width: double.infinity,
                child: M3EButton(
                  style: M3EButtonStyle.outlined,
                  onPressed: onOpenBrowser,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_browser_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Open in Browser'),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Text(
              'Try refreshing, switching reading engines, or opening the article in your browser.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: c.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
