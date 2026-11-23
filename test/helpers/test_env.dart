import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:freedium/core/network/article_resolver.dart';
import 'package:freedium/core/providers/service_providers.dart';
import 'package:freedium/core/services/share_intent_service.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/core/storage/app_database.dart';
import 'package:freedium/core/storage/key_value_store.dart';
import 'package:freedium/core/theme/app_theme.dart';
import 'package:freedium/features/settings/models/reader_settings.dart';
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

/// Long-lived services plus the [ProviderContainer] that shares them with the
/// widget tree and with the test's direct reads.
typedef TestServices = ({
  StorageService storage,
  ArticleResolver resolver,
  ShareIntentService shareIntent,
  ProviderContainer container,
});

TestServices? _latest;

/// Creates fresh services and the container that overrides the app providers.
/// Widgets and direct controller reads in one test therefore see the same
/// instances.
TestServices registerServices({Map<String, dynamic> seed = const {}}) {
  final storage = createTestStorage(seed: seed);
  final resolver = ArticleResolver();
  final shareIntent = ShareIntentService(storage.preferences);
  final container = ProviderContainer(
    overrides: [
      storageServiceProvider.overrideWithValue(storage),
      shareIntentServiceProvider.overrideWithValue(shareIntent),
    ],
  );

  final services = (
    storage: storage,
    resolver: resolver,
    shareIntent: shareIntent,
    container: container,
  );
  _latest = services;
  return services;
}

/// Reads the container created by the most recent [registerServices] call.
ProviderContainer get testContainer =>
    _latest?.container ?? registerServices().container;

const Color testSeedColor = Color(0xFF00695C);

/// Wraps [child] in the theming, scope and localization a screen expects.
Widget wrapTestApp({
  required Widget child,
  TestServices? services,
  ProviderContainer? container,
  List<Override> overrides = const [],
}) {
  ProviderContainer? scope = container ?? services?.container;
  if (scope == null && overrides.isNotEmpty) {
    final active = _latest ?? registerServices();
    scope = ProviderContainer(parent: active.container, overrides: overrides);
  }
  scope ??= (_latest ?? registerServices()).container;
  return UncontrolledProviderScope(
    container: scope,
    child: MaterialApp(
      localizationsDelegates: const [DefaultMaterialLocalizations.delegate],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: child,
    ),
  );
}

/// Persists [settings] as the device's reader defaults.
void seedReaderSettings(StorageService storage, ReaderSettings settings) {
  storage.preferences.readerSettings = settings;
}
