import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app.dart';
import 'core/services/clipboard_service.dart';
import 'core/services/share_intent_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync(() => StorageService().init());
  Get.put(ThemeService());
  await Get.putAsync(() => ShareIntentService().init());
  Get.put(ClipboardService());
  runApp(const Readora());
}
