import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart'
    show WidgetsBinding, WidgetsBindingObserver;

import '../../features/favorites/models/favorite_article.dart';
import '../../features/settings/models/reader_settings.dart';
import '../providers/service_providers.dart';
import '../storage/preferences_store.dart';

/// App-wide theme state, resolved from the saved preference and the platform.
class AppThemeState {
  const AppThemeState({required this.preferredMode, required this.isDarkMode});

  final String preferredMode;
  final bool isDarkMode;

  AppThemeState copyWith({String? preferredMode, bool? isDarkMode}) {
    return AppThemeState(
      preferredMode: preferredMode ?? this.preferredMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

/// Owns the theme mode and keeps it in sync with the OS setting.
final themeControllerProvider =
    NotifierProvider<ThemeController, AppThemeState>(ThemeController.new);

class ThemeController extends Notifier<AppThemeState>
    with WidgetsBindingObserver {
  @override
  AppThemeState build() {
    final preferences = ref.watch(storageServiceProvider).preferences;
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    return AppThemeState(
      preferredMode: preferences.themeMode,
      isDarkMode: preferences.isDarkMode,
    );
  }

  @override
  void didChangePlatformBrightness() {
    final preferences = ref.read(storageServiceProvider).preferences;
    if (state.preferredMode != PreferencesStore.modeSystem) return;
    state = state.copyWith(isDarkMode: preferences.isDarkMode);
  }

  void setThemeMode(String mode) {
    ref.read(storageServiceProvider).preferences.themeMode = mode;
    _sync();
  }

  void toggleTheme(bool dark) {
    setThemeMode(dark ? PreferencesStore.modeDark : PreferencesStore.modeLight);
  }

  void toggleDarkMode() => toggleTheme(!state.isDarkMode);

  void _sync() {
    final preferences = ref.read(storageServiceProvider).preferences;
    state = state.copyWith(
      preferredMode: preferences.themeMode,
      isDarkMode: preferences.isDarkMode,
    );
  }
}

/// The reader's typography, shared by the settings screen and the reader so a
/// change in one is immediately visible in the other.
final readerSettingsProvider =
    NotifierProvider<ReaderSettingsController, ReaderSettings>(
      ReaderSettingsController.new,
    );

class ReaderSettingsController extends Notifier<ReaderSettings> {
  Timer? _persistTimer;
  late PreferencesStore _preferences;

  @override
  ReaderSettings build() {
    _preferences = ref.watch(storageServiceProvider).preferences;
    // Capture the store now: calling ref.read during onDispose trips Riverpod's
    // debug assertion against reading providers while disposing.
    ref.onDispose(() => _flushTo(_preferences));
    return _preferences.readerSettings;
  }

  void update(ReaderSettings settings) {
    state = settings;
    // Dragging the font-size slider must not queue a JSON encode and a database
    // write on every pointer tick; the document itself is restyled immediately
    // by the reader's listener.
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 300), flush);
  }

  void setFontSize(double size) {
    update(
      state.copyWith(
        fontSize: size.clamp(
          ReaderSettings.kMinFontSize,
          ReaderSettings.kMaxFontSize,
        ),
      ),
    );
  }

  /// Writes any pending change immediately.
  void flush() => _flushTo(_preferences);

  void _flushTo(PreferencesStore preferences) {
    _persistTimer?.cancel();
    _persistTimer = null;
    preferences.readerSettings = state;
  }

  /// Re-reads settings in case the reader wrote them while the settings screen
  /// was closed.
  void sync() {
    final stored = _preferences.readerSettings;
    if (stored != state) state = stored;
  }
}

/// The user's library. Favorites live here rather than in the raw store so both
/// the Favorites screen and the reader observe a single reactive source.
final libraryControllerProvider =
    NotifierProvider<LibraryController, List<FavoriteArticle>>(
      LibraryController.new,
    );

class LibraryController extends Notifier<List<FavoriteArticle>> {
  @override
  List<FavoriteArticle> build() =>
      List.unmodifiable(ref.watch(storageServiceProvider).library.favorites);

  bool isFavorite(String url) =>
      state.any((article) => article.url.trim() == url.trim());

  Future<void> toggle(FavoriteArticle article) async {
    await ref.read(storageServiceProvider).library.toggleFavorite(article);
    _refresh();
  }

  Future<void> remove(String url) async {
    final storage = ref.read(storageServiceProvider);
    await storage.library.removeFromFavorites(url);
    await storage.library.removeMeta(url);
    await storage.cache.remove(url);
    _refresh();
  }

  void _refresh() {
    state = List.unmodifiable(
      ref.read(storageServiceProvider).library.favorites,
    );
  }
}
