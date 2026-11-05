import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/support_dialog.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_account_button.dart';
import '../widgets/home_account_section.dart';
import '../widgets/home_hero.dart';
import '../widgets/home_unlock_form.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(
        title: Text('Freedium'),
        actions: [
          HomeAccountButton(),
          SizedBox(width: AppSpacing.xxs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          HomeHero(),
          HomeAccountSection(),
          HomeUnlockForm(),
          SizedBox(height: AppSpacing.scrollEnd),
        ],
      ),

      floatingActionButton: M3EIconButton(
        size: M3EIconButtonSize.md,
        icon: const Icon(M3EIcons.volunteer_activism_rounded),
        tooltip: 'Support Freedium',
        onPressed: () => showSupportDialog(context),
      ),
    );
  }
}
