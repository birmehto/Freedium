import 'package:get/get.dart';

import '../controllers/app_shell_controller.dart';

/// Registers the shell's own state.
///
/// A `lazyPut` singleton, unlike the per-route `create` used elsewhere: the
/// shell is one route for the life of the app, and every tab in it has to see
/// the same selected index.
class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppShellController>(AppShellController.new);
  }
}
