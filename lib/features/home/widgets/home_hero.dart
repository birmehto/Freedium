import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

class HomeHeaderIcon extends StatelessWidget {
  const HomeHeaderIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
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
              theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
              theme.colorScheme.primary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          M3EIcons.auto_stories_rounded,
          size: 48,
          color: isDark ? theme.colorScheme.onPrimary : Colors.white,
        ),
      ),
    );
  }
}

/// Home hero: header icon, headline and tagline.
class HomeHero extends StatelessWidget {
  const HomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 20),
        const Center(child: HomeHeaderIcon()),
        const SizedBox(height: 30),
        Text(
          'Read Freely',
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            height: 1.0,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Unlock premium Medium content instantly.\nNo limits. No paywalls.',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
