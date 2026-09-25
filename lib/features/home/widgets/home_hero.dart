import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

class HomeHeaderIcon extends StatelessWidget {
  const HomeHeaderIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryContainer.withValues(alpha: 0.8),
              colors.primary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          M3EIcons.auto_stories_rounded,
          size: 48,
          color: colors.onPrimary,
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

    return Column(
      children: [
        const SizedBox(height: 20),
        const HomeHeaderIcon(),
        const SizedBox(height: 30),
        Text(
          'Read Freely',
          textAlign: TextAlign.center,
          style: text.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            height: 1,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Unlock premium Medium content instantly.\nNo limits. No paywalls.',
          textAlign: TextAlign.center,
          style: text.titleMedium?.copyWith(
            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
