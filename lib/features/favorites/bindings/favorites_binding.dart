import 'package:get/get.dart';

import '../../../core/services/storage_service.dart';
import '../controllers/favorites_controller.dart';

class FavoritesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FavoritesController>(
      () => FavoritesController(Get.find<StorageService>()),
    );
  }
}
