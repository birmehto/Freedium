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

  @override
  void onInit() {
    super.onInit();
    _loadAppVersion();
    themeMode.value = _themeService.preferredMode;
    readerSettings.value = _storage.preferences.readerSettings;
    preferredMirror.value = _storage.preferences.preferredMirror;
    autoFallback.value = _storage.preferences.autoFallback;
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

    if (!await _openExternal(uri)) {
      _showMessage('No email app found. Email us at $address');
    }
  }

  Future<void> openGitHub() =>
      _openExternal(Uri.parse('https://github.com/birmehto/Freedium'));

  Future<bool> _openExternal(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (error) {
      final exception = AppException.from(error, context: 'openExternal');
      appLog(exception.toString(), name: 'Settings', level: LogLevel.warning);
    }

    _showMessage('Could not open link');
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

  void _showMessage(String message) {
    if (Get.context case final context?) {
      M3ESnackbar.show(context, message: message);
    }
  }
}
