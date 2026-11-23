import '../storage/app_database.dart';
import '../storage/article_cache_store.dart';
import '../storage/key_value_store.dart';
import '../storage/library_store.dart';
import '../storage/preferences_store.dart';

/// Owns the on-device SQLite database and exposes the focused stores.
///
/// Created once during startup and shared through `storageServiceProvider`.
class StorageService {
  /// Production constructor: call [init] before use.
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

  /// Saved article bodies so favorites stay readable without a network.
  late final ArticleCacheStore cache;

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

    // A reopened database is not empty; count what it holds so eviction cannot
    // treat it as fresh and let it grow without bound.
    await cache.refreshTotals();
    return this;
  }

  /// Waits for queued preference writes to reach SQLite.
  ///
  /// Called when the app leaves the foreground so a font-size change made just
  /// before backgrounding is not still sitting in the write queue when the
  /// process is killed.
  Future<void> flush() async {
    final store = _keyValueStore;
    if (store is DriftKeyValueStore) await store.flush();
  }

  /// Closes only the database this service opened. An injected store belongs to
  /// the caller that created it.
  void dispose() {
    final store = _keyValueStore;
    if (store is DriftKeyValueStore) store.close();
  }

  void _attachStores() {
    final store = _keyValueStore!;
    final database = _database!;
    preferences = PreferencesStore(store);
    library = LibraryStore(store);
    cache = ArticleCacheStore(database);
  }
}
