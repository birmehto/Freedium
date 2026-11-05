import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:freedium/core/network/article_resolver.dart';
import 'package:freedium/core/services/auth_service.dart';
import 'package:freedium/core/services/cookie_store.dart';
import 'package:freedium/core/services/share_intent_service.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/core/services/theme_service.dart';
import 'package:freedium/core/storage/app_database.dart';
import 'package:freedium/core/storage/key_value_store.dart';
import 'package:freedium/features/settings/models/reader_settings.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as ui;
import 'package:material_ui/material_ui.dart';

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

/// An in-memory [CookieStore] standing in for the WebView cookie jar.
///
/// Records what the account service wrote and removed so session rules can be
/// asserted without a platform channel.
class MemoryCookieStore implements CookieStore {
  MemoryCookieStore({List<Map<String, String>>? pairs}) : pairs = [...?pairs];

  /// Every cookie the jar currently holds, as single-entry maps.
  final List<Map<String, String>> pairs;

  /// Cookie names passed to [remove], in order.
  final List<String> removed = [];

  /// Cookies passed to [write], as `(url, cookies, domain)`.
  final List<(String, List<Map<String, String>>, String?)> writes = [];

  @override
  Future<List<Map<String, String>>> read(String url) async => pairs;

  @override
  Future<void> write(
    String url,
    List<Map<String, String>> cookies, {
    String? domain,
  }) async {
    writes.add((url, cookies, domain));
  }

  @override
  Future<void> remove(
    String url,
    Iterable<String> names, {
    String? domain,
  }) async {
    removed.addAll(names);
  }
}

/// Registers the app-wide services a feature binding expects.
({
  StorageService storage,
  ThemeService theme,
  ArticleResolver resolver,
  ShareIntentService shareIntent,
  AuthService auth,
  MemoryCookieStore cookies,
})
registerServices({Map<String, dynamic> seed = const {}}) {
  Get.reset();

  final storage = createTestStorage(seed: seed);
  final theme = ThemeService(storage.preferences);
  final resolver = ArticleResolver();
  final shareIntent = ShareIntentService(storage.preferences);
  final cookies = MemoryCookieStore();
  final auth = AuthService(storage, cookies);

  Get.put<StorageService>(storage);
  Get.put<ThemeService>(theme);
  Get.put<ArticleResolver>(resolver);
  Get.put<ShareIntentService>(shareIntent);
  Get.put<AuthService>(auth);
  Get.put<CookieStore>(cookies);

  return (
    storage: storage,
    theme: theme,
    resolver: resolver,
    shareIntent: shareIntent,
    auth: auth,
    cookies: cookies,
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
