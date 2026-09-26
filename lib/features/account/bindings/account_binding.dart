import 'package:get/get.dart';

import '../../../core/services/cookie_store.dart';
import '../controllers/login_controller.dart';

class AccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(Get.find<CookieStore>()),
    );
  }
}
