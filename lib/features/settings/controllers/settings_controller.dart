import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/utils/app_log.dart';
import '../models/reader_settings.dart';

class SettingsController extends GetxController {
  SettingsController(this._themeService, this._storage);

  final ThemeService _themeService;
  final StorageService _storage;

  final appVersion = ''.obs;

  // Appearance
  final themeMode = ''.obs;

  // Reader defaults
  final readerSettings = const ReaderSettings().obs;
  final fontSize = 17.0.obs;

  // Network & source
  final preferredMirror = Rxn<String>();
  final autoFallback = true.obs;

  // Library & storage
  final savedCount = 0.obs;
  final savedSizeBytes = 0.obs;
  final recentSearchCount = 0.obs;

  // Local statistics
  final completedCount = 0.obs;
  final readingMinutes = 0.obs;

  bool get isDarkMode => _themeService.isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadAppVersion();
    fontSize.value = _storage.fontSize;
    themeMode.value = _themeService.preferredMode;
    readerSettings.value = _storage.preferences.readerSettings;
    preferredMirror.value = _storage.preferences.preferredMirror;
    autoFallback.value = _storage.preferences.autoFallback;
    refreshLibrary();
  }

  void refreshLibrary() {
    savedCount.value = _storage.library.savedArticles.length;
    savedSizeBytes.value = _storage.library.savedBytes;
    recentSearchCount.value = _storage.preferences.recentSearches.length;
    final stats = _storage.library.readingStats;
    completedCount.value = (stats['completedCount'] as num?)?.toInt() ?? 0;
    readingMinutes.value = (stats['readingMinutes'] as num?)?.toInt() ?? 0;
  }

  // ─────────────────────────────── appearance ─────────────────────────

  void setThemeMode(String mode) {
    themeMode.value = mode;
    _themeService.setThemeMode(mode);
  }

  void toggleTheme(bool value) {
    _themeService.toggleTheme(value);
    themeMode.value = _themeService.preferredMode;
  }

  void setFontSize(double size) {
    fontSize.value = size;
    _storage.fontSize = size;
    updateReaderSettings(readerSettings.value.copyWith(fontSize: size));
  }

  void updateReaderSettings(ReaderSettings settings) {
    readerSettings.value = settings;
    _storage.preferences.readerSettings = settings;
  }

  // ─────────────────────────────── source ─────────────────────────────

  void setPreferredMirror(String? mirrorId) {
    preferredMirror.value = mirrorId;
    _storage.preferences.preferredMirror = mirrorId;
  }

  void setAutoFallback(bool value) {
    autoFallback.value = value;
    _storage.preferences.autoFallback = value;
  }

  // ───────────────────────────── storage mgmt ─────────────────────────

  void clearSavedArticles() {
    _storage.library.clearSavedArticles();
    refreshLibrary();
  }

  void clearRecentSearches() {
    _storage.preferences.clearRecentSearches();
    refreshLibrary();
  }

  String get savedSizeLabel {
    const kb = 1024;
    const mb = 1024 * 1024;
    final bytes = savedSizeBytes.value;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  // ─────────────────────────────── about ──────────────────────────────

  Future<void> sendFeedback() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'birmehto@gmail.com',
      queryParameters: {'subject': 'Freedium Feedback'},
    );

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        M3ESnackbar.show(
          // ignore: use_build_context_synchronously
          Get.context!,
          message: 'No email app found. Email us at birmehto@gmail.com',
        );
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      final exception = AppException.from(e, context: 'sendFeedback');
      appLog(exception.toString(), name: 'Settings', level: LogLevel.warning);
      M3ESnackbar.show(Get.context!, message: "Couldn't open email app");
    }
  }

  Future<void> openGitHub() async {
    await _openExternal('https://github.com/birmehto/Freedium');
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        M3ESnackbar.show(Get.context!, message: 'Could not open link');
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      final exception = AppException.from(e, context: '_openExternal');
      appLog(exception.toString(), name: 'Settings', level: LogLevel.warning);
      M3ESnackbar.show(Get.context!, message: "Couldn't open link");
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion.value = info.version;
    } catch (e) {
      final exception = AppException.from(e, context: '_loadAppVersion');
      appLog(exception.toString(), name: 'Settings', level: LogLevel.warning);
    }
  }
}
