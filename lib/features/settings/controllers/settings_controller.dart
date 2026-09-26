import 'dart:async';

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

  // Network & source
  final preferredMirror = RxnString();
  final autoFallback = true.obs;

  bool get isDarkMode => _themeService.isDarkMode.value;

  /// Font size is part of the reader settings, not a separate value.
  double get fontSize => readerSettings.value.fontSize;

  /// Whether anything is saved for offline reading.
  bool get hasOfflineArticles => _storage.cache.cachedCount.value > 0;

  /// How many articles are saved for offline reading.
  ///
  /// Read straight off the cache store rather than copied into this controller,
  /// so the number cannot fall out of step with what is actually stored.
  RxInt get cachedArticles => _storage.cache.cachedCount;

  String get offlineSummary {
    final count = _storage.cache.cachedCount.value;
    final articles = count == 1 ? '1 article' : '$count articles';

    return '$articles • ${_storage.cache.formattedSize}';
  }

  @override
  void onInit() {
    super.onInit();
    _loadAppVersion();
    themeMode.value = _themeService.preferredMode;
    readerSettings.value = _storage.preferences.readerSettings;
    preferredMirror.value = _storage.preferences.preferredMirror;
    autoFallback.value = _storage.preferences.autoFallback;

    // Counted again on open, so a cache cleared here or evicted since launch
    // is reflected immediately.
    unawaited(_storage.cache.refreshTotals());
  }

  // ────────────────────────────── offline ────────────────────────────

  /// Empties the offline article cache.
  ///
  /// Favorites and reading positions are untouched: what was saved and where
  /// the reader got to are the user's own data, not a cache.
  /// True while a "Clear saved articles" request is in flight.
  ///
  /// The dialog closes itself once the clear finishes, so a second tap landing
  /// before the first one is done would pop a second route — on Android, the
  /// shell underneath, which leaves the app.
  final isClearingCache = false.obs;

  Future<void> clearOfflineArticles() async {
    if (isClearingCache.value) return;
    isClearingCache.value = true;

    try {
      await _storage.cache.clear();
    } finally {
      isClearingCache.value = false;
    }
  }

  /// Re-reads the reader defaults from storage.
  ///
  /// The reader writes the same settings the settings screen shows, so a font
  /// size changed while reading is picked up when the tab is opened again
  /// instead of showing the value this controller happened to start with.
  void syncReaderSettings() {
    readerSettings.value = _storage.preferences.readerSettings;
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

  // ──────────────────────────────── reader ────────────────────────────

  void setFontSize(double size) {
    updateReaderSettings(
      readerSettings.value.copyWith(
        fontSize: size.clamp(
          ReaderSettings.kMinFontSize,
          ReaderSettings.kMaxFontSize,
        ),
      ),
    );
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

  // ──────────────────────────────── about ────────────────────────────

  Future<void> sendFeedback() async {
    const address = 'birmehto@gmail.com';

    final uri = Uri(
      scheme: 'mailto',
      path: address,
      queryParameters: const {'subject': 'Freedium Feedback'},
    );

    // `reportFailure: false`: the caller owns the message, so the user is not
    // told "could not open link" and "no email app" for one failed attempt.
    if (!await _openExternal(uri, reportFailure: false)) {
      showMessage('No email app found. Email us at $address');
    }
  }

  Future<void> openGitHub() =>
      _openExternal(Uri.parse('https://github.com/birmehto/Freedium'));

  Future<bool> _openExternal(Uri uri, {bool reportFailure = true}) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (error) {
      final exception = AppException.from(error, context: 'openExternal');
      appLog(exception.toString(), name: 'Settings', level: LogLevel.warning);
    }

    if (reportFailure) showMessage('Could not open link');
    return false;
  }

  Future<void> _loadAppVersion() async {
    try {
      appVersion.value = (await PackageInfo.fromPlatform()).version;
    } catch (error) {
      final exception = AppException.from(error, context: 'loadAppVersion');
      appLog(exception.toString(), name: 'Settings', level: LogLevel.warning);
    }
  }

  void showMessage(String message) {
    if (Get.context case final context?) {
      M3ESnackbar.show(context, message: message);
    }
  }
}
