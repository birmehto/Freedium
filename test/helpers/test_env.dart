import 'package:flutter/material.dart';
import 'package:freedium/core/network/article_resolver.dart';
import 'package:freedium/core/services/share_intent_service.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/core/services/theme_service.dart';
import 'package:freedium/core/storage/key_value_store.dart';
import 'package:freedium/features/settings/models/reader_settings.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as ui;

/// Builds a [StorageService] backed by an in-memory key-value store.
///
/// Real store logic is exercised instead of mocked out, so persistence bugs
/// cannot hide behind a fake.
StorageService createTestStorage({Map<String, dynamic> seed = const {}}) {
  final store = MemoryKeyValueStore();
  for (final entry in seed.entries) {
    store.write(entry.key, entry.value);
  }

  return StorageService.withStore(store);
}

/// Registers the app-wide services a feature binding expects.
({
  StorageService storage,
  ThemeService theme,
  ArticleResolver resolver,
  ShareIntentService shareIntent,
})
registerServices({Map<String, dynamic> seed = const {}}) {
  Get.reset();

  final storage = createTestStorage(seed: seed);
  final theme = ThemeService(storage.preferences);
  final resolver = ArticleResolver();
  final shareIntent = ShareIntentService();

  Get.put<StorageService>(storage);
  Get.put<ThemeService>(theme);
  Get.put<ArticleResolver>(resolver);
  Get.put<ShareIntentService>(shareIntent);

  return (
    storage: storage,
    theme: theme,
    resolver: resolver,
    shareIntent: shareIntent,
  );
}

const Color testSeedColor = Color(0xFF00695C);

/// Wraps [child] in the theming and localization a screen expects.
Widget wrapTestApp({required Widget child, GetPage<dynamic>? articleRoute}) {
  return M3ETheme(
    data: M3EThemeData.light(seedColor: testSeedColor),
    child: GetMaterialApp(
      localizationsDelegates: const [ui.DefaultMaterialLocalizations.delegate],
      home: child,
    ),
  );
}

/// Persists [settings] as the device's reader defaults.
void seedReaderSettings(StorageService storage, ReaderSettings settings) {
  storage.preferences.readerSettings = settings;
}
