import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/controllers/app_controllers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/storage/preferences_store.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/widgets/app_snackbar.dart';

class SettingsState {
  const SettingsState({
    this.appVersion = '',
    this.themeMode = PreferencesStore.modeSystem,
    this.preferredMirror,
    this.autoFallback = true,
  });

  final String appVersion;
  final String themeMode;
  final String? preferredMirror;
  final bool autoFallback;

  SettingsState copyWith({
    String? appVersion,
    String? themeMode,
    String? preferredMirror,
    bool? autoFallback,
    bool clearMirror = false,
  }) {
    return SettingsState(
      appVersion: appVersion ?? this.appVersion,
      themeMode: themeMode ?? this.themeMode,
      preferredMirror: clearMirror
          ? null
          : preferredMirror ?? this.preferredMirror,
      autoFallback: autoFallback ?? this.autoFallback,
    );
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final preferences = ref.watch(storageServiceProvider).preferences;
    final theme = ref.watch(themeControllerProvider);
    unawaited(_loadAppVersion());

    return SettingsState(
      themeMode: theme.preferredMode,
      preferredMirror: preferences.preferredMirror,
      autoFallback: preferences.autoFallback,
    );
  }

  void setThemeMode(String mode) {
    ref.read(themeControllerProvider.notifier).setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  void toggleTheme(bool dark) {
    ref.read(themeControllerProvider.notifier).toggleTheme(dark);
    state = state.copyWith(
      themeMode: dark ? PreferencesStore.modeDark : PreferencesStore.modeLight,
    );
  }

  void setPreferredMirror(String? mirrorId) {
    ref.read(storageServiceProvider).preferences.preferredMirror = mirrorId;
    ref.read(articleResolverProvider).setPreferred(mirrorId);
    state = state.copyWith(
      preferredMirror: mirrorId,
      clearMirror: mirrorId == null,
    );
  }

  void setAutoFallback(bool value) {
    ref.read(storageServiceProvider).preferences.autoFallback = value;
    ref.read(articleResolverProvider).autoFallback = value;
    state = state.copyWith(autoFallback: value);
  }

  Future<void> sendFeedback() async {
    const address = 'birmehto@gmail.com';
    final uri = Uri(
      scheme: 'mailto',
      path: address,
      queryParameters: const {'subject': 'Freedium Feedback'},
    );

    if (!await _openExternal(uri, reportFailure: false)) {
      AppSnackbar.message('No email app found. Email us at $address');
    }
  }

  Future<void> openGitHub() =>
      _openExternal(Uri.parse('https://github.com/birmehto/Freedium'));

  /// Opens this app's Play Store page so the reader can leave a rating.
  ///
  /// The `market://` intent goes straight to the Play Store app on Android;
  /// everywhere else (or when no store app is installed) the https URL opens
  /// in a browser instead.
  Future<void> rateApp() async {
    final market = Uri.parse(
      'market://details?id=${AppConstants.playStoreId}',
    );
    if (await _openExternal(market, reportFailure: false)) return;

    await _openExternal(Uri.parse(AppConstants.playStoreUrl));
  }

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

    if (reportFailure) AppSnackbar.message('Could not open link');
    return false;
  }

  Future<void> _loadAppVersion() async {
    try {
      final version = (await PackageInfo.fromPlatform()).version;
      state = state.copyWith(appVersion: version);
    } catch (error) {
      final exception = AppException.from(error, context: 'loadAppVersion');
      appLog(exception.toString(), name: 'Settings', level: LogLevel.warning);
    }
  }
}
