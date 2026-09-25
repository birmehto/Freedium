import 'package:get/get.dart';

import '../storage/app_database.dart';
import '../storage/key_value_store.dart';
import '../storage/library_store.dart';
import '../storage/preferences_store.dart';

/// Owns the on-device SQLite database and exposes the two focused stores.
///
/// Registered as a permanent service during startup, so every feature binding
/// resolves the same [preferences] and [library] instances.
class StorageService extends GetxService {
  /// Production constructor: opens the SQLite database.
  StorageService();

  /// Test constructor: uses an already-prepared [KeyValueStore].
  StorageService.withStore(KeyValueStore store) {
    _keyValueStore = store;
    _attachStores();
  }

  late final PreferencesStore preferences;
  late final LibraryStore library;

  KeyValueStore? _keyValueStore;

  /// Opens the database and warms the synchronous read cache.
  Future<StorageService> init() async {
    final store = DriftKeyValueStore(AppDatabase.open());
    await store.init();

    _keyValueStore = store;
    _attachStores();
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
    preferences = PreferencesStore(store);
    library = LibraryStore(store);
  }
}
