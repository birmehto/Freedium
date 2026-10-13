import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_app_bar.dart';
import '../../support/controllers/support_controller.dart';
import '../../support/widgets/support_dialog.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_hero.dart';
import '../widgets/home_unlock_form.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: Text('Freedium')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [HomeHero(), HomeUnlockForm(), SizedBox(height: 80)],
      ),
      // The way users keep Freedium running: a rewarded video or a donation,
      // offered side by side in one dialog.
      floatingActionButton: M3EFab(
        icon: const Icon(M3EIcons.volunteer_activism_rounded),
        tooltip: 'Support Freedium',
        size: M3EFabSize.regular,
        onPressed: () => showSupportDialog(
          context,
          controller: Get.find<SupportController>(),
        ),
      ),
    );
  }
}
