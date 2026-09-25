import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/theme/app_spacing.dart';

class HomeHeaderIcon extends StatelessWidget {
  const HomeHeaderIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primaryContainer,
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primary,
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.22),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            M3EIcons.auto_stories_rounded,
            size: 40,
            color: colors.onPrimary,
          ),
        ),
      ),
    );
  }
}

class HomeHero extends StatelessWidget {
  const HomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),

          const HomeHeaderIcon(),

          const SizedBox(height: AppSpacing.xl + AppSpacing.xs),

          Text(
            'Read Freely',
            textAlign: TextAlign.center,
            style: text.displaySmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.8,
              height: 1.05,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              'Read the stories you love without limits or paywalls.',
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
