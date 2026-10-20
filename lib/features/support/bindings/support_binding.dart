import 'package:get/get.dart';

import '../controllers/support_controller.dart';

class SupportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupportController>(SupportController.new);
  }
}
