import 'package:flutter/widgets.dart';

import '../../features/settings/models/reader_settings.dart';
import 'key_value_store.dart';

/// Device-level preferences: theme, typography, search & mirror options.
///
/// Kept separate from [LibraryStore] so reading data and device settings do
/// not share one blob of responsibility.
class PreferencesStore {
  PreferencesStore(this._box);

  static const kThemeMode = 'theme_mode';
  static const kReaderSettings = 'reader_settings';
  static const kPreferredMirror = 'preferred_mirror';
  static const kAutoFallback = 'auto_fallback';

  final KeyValueStore _box;

  // ─────────────────────────────── theme ───────────────────────────────

  /// One of `system`, `light`, `dark`.
  String get themeMode {
    final raw = _box.read(kThemeMode);
    if (raw is bool) {
      return raw ? 'dark' : 'light';
    }
    return (raw as String?) ?? 'system';
  }

  set themeMode(String value) {
    _box.write(kThemeMode, value);
  }

  /// Effective brightness taking the platform into account for `system`.
  bool get isDarkMode {
    final mode = themeMode;
    if (mode == 'light') return false;
    if (mode == 'dark') return true;
    try {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    } catch (_) {
      return false;
    }
  }

  set isDarkMode(bool value) => themeMode = value ? 'dark' : 'light';

  // ─────────────────────────── reader settings ─────────────────────────

  ReaderSettings get readerSettings {
    final raw = _box.read(kReaderSettings);
    if (raw is Map) {
      return ReaderSettings.fromJson(Map<String, dynamic>.from(raw));
    }
    return const ReaderSettings();
  }

  set readerSettings(ReaderSettings settings) {
    _box.write(kReaderSettings, settings.toJson());
  }

  /// Convenience accessor kept for feature parity with the earlier API.
  double get fontSize => readerSettings.fontSize;

  set fontSize(double value) {
    readerSettings = readerSettings.copyWith(fontSize: value);
  }

  // ───────────────────────────── mirror options ────────────────────────

  String? get preferredMirror => _box.read(kPreferredMirror) as String?;

  set preferredMirror(String? value) {
    if (value == null) {
      _box.remove(kPreferredMirror);
    } else {
      _box.write(kPreferredMirror, value);
    }
  }

  bool get autoFallback => _box.read(kAutoFallback) as bool? ?? true;

  set autoFallback(bool value) => _box.write(kAutoFallback, value);
}
