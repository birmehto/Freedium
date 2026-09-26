import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/network/article_resolver.dart';
import 'core/services/auth_service.dart';
import 'core/services/clipboard_service.dart';
import 'core/services/cookie_store.dart';
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

  // Restores a saved Medium session, if there is one. The account is optional,
  // so this never blocks or gates the app. The cookie store is registered as
  // well because the sign-in screen reads the jar to notice a new session.
  const cookies = WebViewCookieStore();
  Get.put<CookieStore>(cookies);
  await Get.putAsync(() => AuthService(storage, cookies).init());

  // One resolver for the whole app, so what it learns about a mirror helps the
  // next article.
  Get.put(ArticleResolver());

  runApp(const Freedium());
}
