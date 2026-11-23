import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// The app's editorial theme: near-black ink on paper-white (or the reverse),
/// a serif for headlines and a restrained sans for everything else.
abstract final class AppTheme {
  static const _lightInk = Color(0xFF111111);
  static const _lightPaper = Color(0xFFFFFFFF);
  static const _lightMuted = Color(0xFF6B6B6B);
  static const _lightRule = Color(0xFFE8E8E8);

  static const _darkInk = Color(0xFFF2F2F0);
  static const _darkPaper = Color(0xFF0C0C0C);
  static const _darkMuted = Color(0xFFA1A1A1);
  static const _darkRule = Color(0xFF292929);

  /// Medium's accent is deliberately small and desaturated — used for the
  /// unread dot, links and the active tab, never as a large color block.
  static const lightAccent = Color(0xFF1A8917);
  static const darkAccent = Color(0xFF4CAF50);

  /// Built once: `MaterialApp` watches the theme mode, and rebuilding a
  /// `ThemeData` (including resolving every Google font) on each rebuild is
  /// pure overhead. Stable identity also lets Flutter skip unchanged work.
  static final ThemeData _lightTheme = _build(Brightness.light);
  static final ThemeData _darkTheme = _build(Brightness.dark);

  static ThemeData light() => _lightTheme;
  static ThemeData dark() => _darkTheme;

  static ThemeMode themeMode(String mode) => switch (mode) {
    'system' => ThemeMode.system,
    'light' => ThemeMode.light,
    _ => ThemeMode.dark,
  };

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final ink = dark ? _darkInk : _lightInk;
    final paper = dark ? _darkPaper : _lightPaper;
    final muted = dark ? _darkMuted : _lightMuted;
    final rule = dark ? _darkRule : _lightRule;
    final accent = dark ? darkAccent : lightAccent;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: ink,
      onPrimary: paper,
      secondary: muted,
      onSecondary: paper,
      tertiary: accent,
      onTertiary: paper,
      error: const Color(0xFFB3261E),
      onError: paper,
      surface: paper,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: rule,
      outlineVariant: rule,
    );

    TextStyle sans(double size, {FontWeight weight = FontWeight.w400}) =>
        GoogleFonts.inter(fontSize: size, fontWeight: weight, color: ink);
    TextStyle serif(double size, {FontWeight weight = FontWeight.w400}) =>
        GoogleFonts.sourceSerif4(
          fontSize: size,
          fontWeight: weight,
          color: ink,
        );

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: paper,
      canvasColor: paper,
      cardColor: paper,
      dividerColor: rule,
      primaryColor: ink,
      fontFamily: GoogleFonts.inter().fontFamily,
      platform: TargetPlatform.android,
      textTheme: TextTheme(
        displayLarge: serif(42, weight: FontWeight.w700),
        displayMedium: serif(36, weight: FontWeight.w700),
        displaySmall: serif(30, weight: FontWeight.w700),
        headlineLarge: serif(28, weight: FontWeight.w700),
        headlineMedium: serif(24, weight: FontWeight.w600),
        headlineSmall: serif(21, weight: FontWeight.w600),
        titleLarge: serif(20, weight: FontWeight.w600),
        titleMedium: sans(16, weight: FontWeight.w600),
        titleSmall: sans(14, weight: FontWeight.w600),
        bodyLarge: sans(17),
        bodyMedium: sans(15),
        bodySmall: sans(13),
        labelLarge: sans(14, weight: FontWeight.w600),
        labelMedium: sans(12, weight: FontWeight.w600),
        labelSmall: sans(11),
      ),
    );
  }

  /// Shared color helpers so screens do not hard-code dark-mode branches.
  static Color ink(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color paper(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color muted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color rule(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;
}
