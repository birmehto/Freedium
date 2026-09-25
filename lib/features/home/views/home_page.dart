import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_app_bar.dart';
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
        children: const [HomeHero(), HomeUnlockForm(), SizedBox(height: 60)],
      ),
    );
  }
}
