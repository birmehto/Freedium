import 'package:get/get.dart';

import '../../../core/network/article_resolver.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/theme_service.dart';
import '../controllers/article_controller.dart';

class ArticleBinding extends Bindings {
  @override
  void dependencies() {
    // `create` rather than `lazyPut`: a second article route (a share intent
    // arriving while a reader is open) would otherwise find the first route's
    // controller — already initialized with the *other* article — and share it,
    // so the second reader showed the first article and the first route lost
    // its controller when the second one was popped.
    Get.create<ArticleController>(
      () => ArticleController(
        Get.find<ClipboardService>(),
        Get.find<StorageService>(),
        Get.find<ThemeService>(),
        Get.find<ArticleResolver>(),
      ),
    );
  }
}
