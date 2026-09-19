import 'package:get/get.dart';

import '../storage/app_database.dart';
import '../storage/key_value_store.dart';
import '../storage/library_store.dart';
import '../storage/preferences_store.dart';

/// Owns the on-device database and exposes the two focused stores.
///
/// Device settings and reading data are kept in separate stores
/// ([PreferencesStore], [LibraryStore]); this facade only wires them up and
/// keeps a thin backward-compatible API for the early controllers.
class StorageService extends GetxService {
  PreferencesStore? _preferences;
  LibraryStore? _library;
  bool _connected = false;

  Future<StorageService> init() async {
    final store = DriftKeyValueStore(AppDatabase.open());
    await store.init();
    _preferences = PreferencesStore(store);
    _library = LibraryStore(store);
    _connected = true;
    return this;
  }

  bool get isConnected => _connected;

  PreferencesStore get preferences =>
      _preferences ??= PreferencesStore(MemoryKeyValueStore());

  LibraryStore get library => _library ??= LibraryStore(MemoryKeyValueStore());

  // ─────────────────────────── legacy API ──────────────────────────────
  // Kept so existing controllers and tests keep working unchanged; all
  // members now delegate to the focused stores.

  bool get isDarkMode => preferences.isDarkMode;
  set isDarkMode(bool value) => preferences.isDarkMode = value;

  double get fontSize => preferences.fontSize;
  set fontSize(double value) => preferences.fontSize = value;

  RxInt get favoritesRevision => library.favoritesRevision;

  List<dynamic> get favorites => library.favorites;

  Future<void> addToFavorites(Map<String, dynamic> item) =>
      library.addToFavorites(item);

  Future<void> removeFromFavorites(String url) =>
      library.removeFromFavorites(url);

  bool isFavorite(String url) => library.isFavorite(url);
}
