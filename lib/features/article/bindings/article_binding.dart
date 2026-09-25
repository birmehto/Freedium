import 'package:get/get.dart';

import '../../../core/network/article_resolver.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/theme_service.dart';
import '../controllers/article_controller.dart';

class ArticleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ArticleController>(
      () => ArticleController(
        Get.find<ClipboardService>(),
        Get.find<StorageService>(),
        Get.find<ThemeService>(),
        Get.find<ArticleResolver>(),
      ),
    );
  }
}
