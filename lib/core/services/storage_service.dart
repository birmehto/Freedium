import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageService extends GetxService {
  late final GetStorage _box;

  static const _themeModeKey = 'theme_mode';
  static const _fontSizeKey = 'font_size';
  static const _favoritesKey = 'favorites_list';
  static const _readingProgressKey = 'reading_progress';

  Future<StorageService> init() async {
    _box = GetStorage();
    await _box.initStorage;
    return this;
  }

  bool get isDarkMode => _box.read(_themeModeKey) ?? true;
  set isDarkMode(bool value) => _box.write(_themeModeKey, value);

  double get fontSize => _box.read(_fontSizeKey) ?? 17.0;
  set fontSize(double value) => _box.write(_fontSizeKey, value);

  // --- Reading progress ---

  Map<String, dynamic> get _readingProgress =>
      Map<String, dynamic>.from(_box.read(_readingProgressKey) ?? {});

  Future<void> saveReadingProgress(String url, double scrollY) async {
    final data = Map<String, dynamic>.from(_readingProgress);
    data[url] = {
      'scrollY': scrollY,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _box.write(_readingProgressKey, data);
  }

  double? getReadingProgress(String url) {
    final entry = _readingProgress[url];
    if (entry is Map) {
      return (entry['scrollY'] as num?)?.toDouble();
    }
    return null;
  }

  // --- Favorites ---

  /// Bumped on every add/remove so observers stay in sync.
  final favoritesRevision = 0.obs;

  List<dynamic> get favorites => _box.read(_favoritesKey) ?? [];

  Future<void> addToFavorites(Map<String, dynamic> item) async {
    final list = favorites;

    if (list.any((e) => e['url'] == item['url'])) return;

    await _box.write(_favoritesKey, [item, ...list]);
    favoritesRevision.value++;
  }

  Future<void> removeFromFavorites(String url) async {
    final list = favorites..removeWhere((e) => e['url'] == url);
    await _box.write(_favoritesKey, list);
    favoritesRevision.value++;
  }

  bool isFavorite(String url) => favorites.any((e) => e['url'] == url);
}
