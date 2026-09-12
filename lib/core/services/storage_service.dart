import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageService extends GetxService {
  late final GetStorage _box;

  static const _themeModeKey = 'theme_mode';
  static const _fontSizeKey = 'font_size';
  static const _fontFamilyKey = 'font_family';
  static const _favoritesKey = 'favorites_list';

  Future<StorageService> init() async {
    _box = GetStorage();
    await _box.initStorage;
    return this;
  }

  bool get isDarkMode => _box.read(_themeModeKey) ?? true;
  set isDarkMode(bool value) => _box.write(_themeModeKey, value);

  double get fontSize => _box.read(_fontSizeKey) ?? 16.0;
  set fontSize(double value) => _box.write(_fontSizeKey, value);

  String get fontFamily => _box.read(_fontFamilyKey) ?? 'Inter';
  set fontFamily(String value) => _box.write(_fontFamilyKey, value);

  List<dynamic> get favorites => _box.read(_favoritesKey) ?? [];

  Future<void> addToFavorites(Map<String, dynamic> item) async {
    final list = favorites;

    if (list.any((e) => e['url'] == item['url'])) return;

    await _box.write(_favoritesKey, [item, ...list]);
  }

  Future<void> removeFromFavorites(String url) async {
    final list = favorites..removeWhere((e) => e['url'] == url);
    await _box.write(_favoritesKey, list);
  }

  bool isFavorite(String url) => favorites.any((e) => e['url'] == url);
}
