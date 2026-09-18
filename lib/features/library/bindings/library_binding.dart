import 'package:get/get.dart';

import '../../../core/services/storage_service.dart';
import '../controllers/library_controller.dart';

class LibraryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LibraryController>(
      () => LibraryController(Get.find<StorageService>()),
    );
  }
}
