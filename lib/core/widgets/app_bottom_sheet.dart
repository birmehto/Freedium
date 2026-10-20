import 'package:material_ui/material_ui.dart';

import '../theme/app_spacing.dart';

/// Modal bottom-sheet content used by settings and the reader.
///
/// Sits inside [M3EBottomSheet], which supplies the surface, drag handle and
/// dismissal; this provides the standard title and scrolling body so callers
/// only supply the content.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}
