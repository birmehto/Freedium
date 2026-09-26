import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/medium_profile.dart';

/// A signed-in Medium author's profile: who they are and how large their
/// audience is.
///
/// Rendered from a cached snapshot, so it is safe to show the moment the
/// session is restored and before any network call has completed. Every count
/// is optional and the whole stat row is hidden when Medium rendered none.
class MediumProfileCard extends StatelessWidget {
  const MediumProfileCard({required this.profile, super.key, this.footer});

  final MediumProfile profile;

  /// Optional actions rendered under the stats, such as refresh and sign out.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return M3ECard(
      variant: M3ECardVariant.outlined,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(profile: profile),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      profile.mention,
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (profile.bio case final String bio when bio.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              bio,
              style: text.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          if (profile.hasStats) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                if (profile.followerCount case final int followers)
                  _Stat(
                    icon: M3EIcons.people_alt_rounded,
                    value: _formatCount(followers),
                    label: followers == 1 ? 'Follower' : 'Followers',
                  ),
                if (profile.followerCount != null &&
                    profile.publicationCount != null)
                  const SizedBox(width: AppSpacing.xl),
                if (profile.publicationCount case final int posts)
                  _Stat(
                    icon: M3EIcons.article_rounded,
                    value: _formatCount(posts),
                    label: posts == 1 ? 'Post' : 'Posts',
                  ),
              ],
            ),
          ],

          if (footer case final Widget footer) ...[
            const SizedBox(height: AppSpacing.lg),
            footer,
          ],
        ],
      ),
    );
  }

  /// Medium's own compact form, which stays readable at a glance.
  static String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
    }
    return '$value';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});

  final MediumProfile profile;

  static const double size = 56;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: switch (profile.avatarUrl) {
          // A broken or slow image must not collapse the card, so the
          // placeholder stands in until the real avatar arrives.
          final String url => Image.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const _AvatarPlaceholder(),
            loadingBuilder: (context, child, loading) =>
                loading == null ? child : const _AvatarPlaceholder(),
          ),
          _ => const _AvatarPlaceholder(),
        },
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.primaryContainer,
      child: Icon(
        M3EIcons.person_rounded,
        size: 30,
        color: context.colors.onPrimaryContainer,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Semantics(
      label: '$value $label',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: AppSpacing.xs + AppSpacing.xxs),
          Text(
            value,
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
