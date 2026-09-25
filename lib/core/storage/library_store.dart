import 'package:get/get_rx/get_rx.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

import '../../features/article/models/article_meta.dart';
import 'key_value_store.dart';

/// Reading data: favorites.
///
/// Separate from [PreferencesStore] so content data stays isolated from
/// device settings.
class LibraryStore {
  LibraryStore(this._box);

  static const kFavorites = 'favorites_list';

  final KeyValueStore _box;

  /// Emits on every favorites mutation so list views can rebuild reactively.
  final RxInt favoritesRevision = 0.obs;

  // ─────────────────────────────── favorites ───────────────────────────

  List<Map<String, dynamic>> get favorites {
    final raw = _box.read(kFavorites);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  bool isFavorite(String url) {
    final target = url.trim();
    return favorites.any((f) => (f['url'] as String? ?? '').trim() == target);
  }

  Future<void> addToFavorites(Map<String, dynamic> item) async {
    final existing = List<Map<String, dynamic>>.from(favorites);
    existing.removeWhere(
      (f) => (f['url'] as String? ?? '').trim() == (item['url'] ?? '').trim(),
    );
    existing.insert(0, item);
    await _box.write(kFavorites, existing);
    favoritesRevision.value++;
  }

  Future<void> removeFromFavorites(String url) async {
    final existing = favorites
        .where((f) => (f['url'] as String? ?? '').trim() != url.trim())
        .toList();
    await _box.write(kFavorites, existing);
    favoritesRevision.value++;
  }

  Future<void> clearFavorites() async {
    await _box.write(kFavorites, <Map<String, dynamic>>[]);
    favoritesRevision.value++;
  }

  // ─────────────────────────────── metadata ────────────────────────────

  Map<String, ArticleMeta> get cachedMeta {
    final raw = _box.read('cached_meta');
    if (raw is Map) {
      return Map<String, dynamic>.from(raw).map(
        (key, value) => MapEntry(
          key,
          ArticleMeta.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      );
    }
    return {};
  }

  void cacheMeta(String url, ArticleMeta meta) {
    final current = cachedMeta;
    current[url] = meta;
    _box.write('cached_meta', current.map((k, v) => MapEntry(k, v.toJson())));
  }
}
