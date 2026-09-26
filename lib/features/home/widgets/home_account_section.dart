import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../account/widgets/medium_profile_card.dart';
import 'home_hero.dart';

/// The top of Home, which is either the welcome hero or the signed-in reader's
/// Medium profile.
///
/// Both branches keep the URL form directly below, so signing in never changes
/// what the screen is for.
class HomeAccountSection extends StatelessWidget {
  const HomeAccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();

    return Obx(() {
      final profile = auth.user.value;

      if (profile == null) return const HomeHero();

      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: MediumProfileCard(profile: profile),
      );
    });
  }
}
