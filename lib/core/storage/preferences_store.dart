import 'package:material_ui/material_ui.dart' show WidgetsBinding, Brightness;

import '../../features/settings/models/reader_settings.dart';
import 'key_value_store.dart';

/// Device-level preferences: theme, reader typography and mirror options.
///
/// Kept separate from [LibraryStore] so reading data and device settings never
/// share a single blob of responsibility.
class PreferencesStore {
  PreferencesStore(this._store);

  static const String themeModeKey = 'theme_mode';
  static const String readerSettingsKey = 'reader_settings';
  static const String preferredMirrorKey = 'preferred_mirror';
  static const String autoFallbackKey = 'auto_fallback';

  /// The last URL that arrived through a share intent and was opened.
  ///
  /// Persisted rather than kept in memory because the re-delivery that makes
  /// this necessary happens after Android has thrown the process away, so an
  /// in-memory flag would start empty and the repeat would be opened again.
  static const String lastSharedUrlKey = 'last_shared_url';

  static const String modeSystem = 'system';
  static const String modeLight = 'light';
  static const String modeDark = 'dark';

  final KeyValueStore _store;

  /// The reader settings are read on every CSS injection and slider tick, so
  /// the decoded value is kept until the stored row actually changes. The raw
  /// map is compared by identity because every write replaces it.
  Object? _readerSettingsRaw;
  ReaderSettings? _readerSettingsCache;

  // ─────────────────────────────── theme ───────────────────────────────

  /// Either [modeLight] or [modeDark].
  ///
  /// Fresh installs start dark. Older builds allowed a [modeSystem] choice;
  /// that stored value is resolved to the device's current brightness so those
  /// users keep the appearance they had instead of being reset.
  String get themeMode {
    final raw = _store.read(themeModeKey);

    // Pre-1.0 builds persisted a boolean instead of the mode name.
    if (raw is bool) return raw ? modeDark : modeLight;
    if (raw is String && raw.isNotEmpty) {
      if (raw == modeSystem) {
        return platformBrightness == Brightness.dark ? modeDark : modeLight;
      }
      return raw;
    }

    return modeDark;
  }

  set themeMode(String value) {
    _store.write(themeModeKey, value);
  }

  /// Effective brightness, resolving [modeSystem] against the platform.
  bool get isDarkMode => switch (themeMode) {
    modeLight => false,
    modeDark => true,
    _ => platformBrightness == Brightness.dark,
  };

  set isDarkMode(bool value) => themeMode = value ? modeDark : modeLight;

  /// The brightness the OS is currently reporting.
  Brightness get platformBrightness {
    try {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    } catch (_) {
      // No binding available (early boot or a pure Dart test).
      return Brightness.light;
    }
  }

  // ─────────────────────────── reader settings ─────────────────────────

  ReaderSettings get readerSettings {
    final raw = _store.read(readerSettingsKey);
    if (identical(raw, _readerSettingsRaw) && _readerSettingsCache != null) {
      return _readerSettingsCache!;
    }

    final parsed = raw is Map
        ? ReaderSettings.fromJson(Map<String, dynamic>.from(raw))
        : const ReaderSettings();
    _readerSettingsRaw = raw;
    _readerSettingsCache = parsed;
    return parsed;
  }

  set readerSettings(ReaderSettings settings) {
    _readerSettingsRaw = null;
    _readerSettingsCache = null;
    _store.write(readerSettingsKey, settings.toJson());
  }

  // ───────────────────────────── mirror options ────────────────────────

  /// The user-pinned mirror id, or `null` to let the resolver choose.
  String? get preferredMirror => _store.read(preferredMirrorKey) as String?;

  set preferredMirror(String? value) {
    if (value == null) {
      _store.remove(preferredMirrorKey);
    } else {
      _store.write(preferredMirrorKey, value);
    }
  }

  bool get autoFallback => _store.read(autoFallbackKey) as bool? ?? true;

  set autoFallback(bool value) {
    _store.write(autoFallbackKey, value);
  }

  // ──────────────────────────────── shares ───────────────────────────────

  /// The last URL a share intent asked the app to open, or `null`.
  ///
  /// Android re-delivers the intent that started a task whenever that task is
  /// relaunched, so this is how a re-delivery is told apart from a new share.
  String? get lastSharedUrl => _store.read(lastSharedUrlKey) as String?;

  set lastSharedUrl(String? value) {
    if (value == null) {
      _store.remove(lastSharedUrlKey);
    } else {
      _store.write(lastSharedUrlKey, value);
    }
  }

  /// Forgets the last share, so the next one opens even if it is the same URL.
  void forgetLastShare() => _store.remove(lastSharedUrlKey);
}
