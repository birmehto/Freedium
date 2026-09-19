import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_app_bar.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_hero.dart';
import '../widgets/home_unlock_form.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            controller.focusUrlField,
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            controller.openArticle,
      },
      child: Scaffold(
        appBar: const AppAppBar(title: 'Freedium'),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [HomeHero(), HomeUnlockForm(), SizedBox(height: 60)],
        ),
      ),
    );
  }
}
