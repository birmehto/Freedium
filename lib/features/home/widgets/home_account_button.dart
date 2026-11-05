import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../account/widgets/medium_profile_card.dart';

/// The Home app bar's account button.
///
/// Signed out it offers sign-in; signed in it shows the reader's avatar and
/// opens the account sheet, so refresh and sign-out are reachable without
/// hunting through Settings.
class HomeAccountButton extends StatelessWidget {
  const HomeAccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();

    return Obx(() {
      final profile = auth.user.value;

      if (profile == null) {
        return M3EIconButton(
          icon: const Icon(M3EIcons.account_circle_rounded),
          tooltip: 'Sign in to Medium',
          onPressed: auth.isBusy.value ? null : auth.signIn,
        );
      }

      return M3EIconButton(
        icon: _Avatar(url: profile.avatarUrl),
        tooltip: 'Medium account',
        onPressed: auth.isBusy.value ? null : showAccountSheet,
      );
    });
  }
}

/// Account actions for a signed-in reader.
void showAccountSheet() {
  final auth = Get.find<AuthService>();

  Get.bottomSheet(
    AppBottomSheet(
      title: 'Medium account',
      child: Obx(() {
        final profile = auth.user.value;
        if (profile == null) return const SizedBox.shrink();

        return MediumProfileCard(
          profile: profile,
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                variant: AppButtonVariant.text,
                isFullWidth: true,
                isLoading: auth.isBusy.value,
                icon: const Icon(M3EIcons.refresh_rounded, size: 20),
                label: const Text('Refresh profile'),
                onPressed: () async {
                  final refreshed = await auth.refreshProfile();

                  // A failed refresh signs the reader out, which empties the
                  // sheet; only a success has something left to show.
                  if (refreshed) Get.back<void>();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                variant: AppButtonVariant.outlined,
                isFullWidth: true,
                icon: const Icon(M3EIcons.logout_rounded, size: 20),
                label: const Text('Sign out'),
                onPressed: () async {
                  await auth.signOut();
                  Get.back<void>();
                },
              ),
            ],
          ),
        );
      }),
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 28,
        height: 28,
        child: switch (url) {
          final String url => Image.network(
            url,
            width: 28,
            height: 28,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const _AvatarPlaceholder(),
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
      child: const Icon(M3EIcons.person_rounded, size: 20),
    );
  }
}
