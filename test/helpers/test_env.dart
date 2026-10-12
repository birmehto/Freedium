import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:freedium/core/network/article_resolver.dart';
import 'package:freedium/core/services/ad_service.dart';
import 'package:freedium/core/services/share_intent_service.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/core/services/theme_service.dart';
import 'package:freedium/core/storage/app_database.dart';
import 'package:freedium/core/storage/key_value_store.dart';
import 'package:freedium/features/settings/models/reader_settings.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as ui;

/// Builds a [StorageService] backed by an in-memory key-value store.
///
/// Real store logic is exercised instead of mocked out, so persistence bugs
/// cannot hide behind a fake. The article cache and reading progress live in
/// Drift tables rather than the key-value store, so they get a real (in-memory)
/// database instead.
StorageService createTestStorage({Map<String, dynamic> seed = const {}}) {
  // Every test builds its own database, so drift's "this database class was
  // opened more than once" warning is expected here and would only be noise.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final store = MemoryKeyValueStore();
  for (final entry in seed.entries) {
    store.write(entry.key, entry.value);
  }

  return StorageService.withStore(
    store,
    database: AppDatabase.forTesting(NativeDatabase.memory()),
  );
}

/// Registers the app-wide services a feature binding expects.
({
  StorageService storage,
  ThemeService theme,
  ArticleResolver resolver,
  ShareIntentService shareIntent,
  AdService ads,
})
registerServices({Map<String, dynamic> seed = const {}}) {
  Get.reset();

  final storage = createTestStorage(seed: seed);
  final theme = ThemeService(storage.preferences);
  final resolver = ArticleResolver();
  final shareIntent = ShareIntentService(storage.preferences);
  final ads = FakeAdService();

  Get.put<StorageService>(storage);
  Get.put<ThemeService>(theme);
  Get.put<ArticleResolver>(resolver);
  Get.put<ShareIntentService>(shareIntent);
  Get.put<AdService>(ads);

  return (
    storage: storage,
    theme: theme,
    resolver: resolver,
    shareIntent: shareIntent,
    ads: ads,
  );
}

/// A controllable [AdService] stand-in, so ad-driven flows can be tested without
/// a device or the Google Mobile Ads SDK.
class FakeAdService implements AdService {
  FakeAdService({this.outcome = RewardedAdOutcome.earnedReward});

  /// The outcome the next [showRewarded] call reports.
  RewardedAdOutcome outcome;

  /// How many times [showRewarded] was called.
  int showCount = 0;

  /// Whether [initialize] was called.
  bool initialized = false;

  @override
  final RxBool isReady = true.obs;

  @override
  Future<void> initialize() async => initialized = true;

  @override
  Future<RewardedAdOutcome> showRewarded() async {
    showCount++;
    return outcome;
  }
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
