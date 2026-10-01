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

  final storage = await Get.putAsync(() => StorageService().init());
  Get.put(ThemeService(storage.preferences));
  await Get.putAsync(() => ShareIntentService().init());
  Get.put(ClipboardService());

  Get.put(ArticleResolver());

  runApp(const Freedium());
}
