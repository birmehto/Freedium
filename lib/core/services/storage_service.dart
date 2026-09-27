import 'package:get/get.dart';

import '../storage/app_database.dart';
import '../storage/article_cache_store.dart';
import '../storage/key_value_store.dart';
import '../storage/library_store.dart';
import '../storage/preferences_store.dart';
import '../storage/reading_progress_store.dart';

/// Owns the on-device SQLite database and exposes the focused stores.
///
/// Registered as a permanent service during startup, so every feature binding
/// resolves the same [preferences], [library], [cache] and [progress]
/// instances.
class StorageService extends GetxService {
  /// Production constructor: opens the SQLite database.
  StorageService();

  /// Test constructor: uses an already-prepared [KeyValueStore] and [database].
  StorageService.withStore(
    KeyValueStore store, {
    required AppDatabase database,
  }) {
    _keyValueStore = store;
    _database = database;
    _attachStores();
  }

  late final PreferencesStore preferences;
  late final LibraryStore library;

  /// The articles behind the reader's favorites, kept on the device so they can
  /// be read without a network.
  late final ArticleCacheStore cache;

  /// How far the reader has got through each article.
  late final ReadingProgressStore progress;

  KeyValueStore? _keyValueStore;
  AppDatabase? _database;

  /// Opens the database and warms the synchronous read cache.
  Future<StorageService> init() async {
    final database = AppDatabase.open();
    final store = DriftKeyValueStore(database);
    await store.init();

    _keyValueStore = store;
    _database = database;
    _attachStores();

    // Counted up front so eviction knows what the store already holds, rather
    // than treating a reopened database as empty and letting it grow unchecked.
    await cache.refreshTotals();
    return this;
  }

  @override
  void onClose() {
    // Only close what this service opened; an injected store belongs to the
    // caller that created it.
    final store = _keyValueStore;
    if (store is DriftKeyValueStore) store.close();
    super.onClose();
  }

  void _attachStores() {
    final store = _keyValueStore!;
    final database = _database!;
    preferences = PreferencesStore(store);
    library = LibraryStore(store);
    cache = ArticleCacheStore(database);
    progress = ReadingProgressStore(database);
  }
}
