import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/network/article_resolver.dart';
import 'core/services/clipboard_service.dart';
import 'core/services/share_intent_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Registration order matters: later services depend on the ones above them.
  final storage = await Get.putAsync(() => StorageService().init());
  Get.put(ThemeService(storage.preferences));
  await Get.putAsync(() => ShareIntentService().init());
  Get.put(ClipboardService());

  // One resolver for the whole app, so what it learns about a mirror helps the
  // next article.
  Get.put(ArticleResolver());

  runApp(const Freedium());
}
