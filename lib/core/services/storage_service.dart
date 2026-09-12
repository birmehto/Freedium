import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageService extends GetxService {
  late GetStorage _box;

  Future<StorageService> init() async {
    _box = GetStorage();
    await _box.initStorage;
    return this;
  }

  // Keys
  static const String _themeModeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size';
  static const String _fontFamilyKey = 'font_family';
  static const String _favoritesKey = 'favorites_list';
  static const String _scrollPositionsKey = 'scroll_positions_map';

  // Theme
  bool get isDarkMode => _box.read(_themeModeKey) ?? true;
  set isDarkMode(bool value) => _box.write(_themeModeKey, value);

  // Font Size
  double get fontSize => _box.read(_fontSizeKey) ?? 16.0;
  set fontSize(double value) => _box.write(_fontSizeKey, value);

  // Font Family
  String get fontFamily => _box.read(_fontFamilyKey) ?? 'Inter';
  set fontFamily(String value) => _box.write(_fontFamilyKey, value);

  // Favorites
  List<dynamic> get favorites => _box.read(_favoritesKey) ?? [];

  Future<void> addToFavorites(Map<String, dynamic> item) async {
    final list = favorites;
    if (!list.any((element) => element['url'] == item['url'])) {
      list.insert(0, item);
      await _box.write(_favoritesKey, list);
    }
  }

  Future<void> removeFromFavorites(String url) async {
    final list = favorites;
    list.removeWhere((element) => element['url'] == url);
    await _box.write(_favoritesKey, list);
  }

  bool isFavorite(String url) {
    return favorites.any((element) => element['url'] == url);
  }

  // Scroll Positions
  Map<String, dynamic> get _scrollPositions =>
      _box.read(_scrollPositionsKey) ?? {};

  Future<void> saveScrollPosition(String url, int y, double percentage) async {
    final map = Map<String, dynamic>.from(_scrollPositions);
    map[url] = {
      'y': y,
      'percentage': percentage,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _box.write(_scrollPositionsKey, map);
  }

  Map<String, dynamic>? getScrollPosition(String url) {
    final map = _scrollPositions;
    if (map.containsKey(url)) {
      return Map<String, dynamic>.from(map[url]);
    }
    return null;
  }
}
