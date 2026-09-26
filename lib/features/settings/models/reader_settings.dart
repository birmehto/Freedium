import 'reader_theme_mode.dart';

/// Typography + appearance settings applied to the embedded reader.
class ReaderSettings {
  const ReaderSettings({
    this.themeMode = ReaderThemeMode.system,
    this.fontFamily = kDefaultFontFamily,
    this.fontSize = 17.0,
  });

  /// Stored settings are read back with the same care they are written: a
  /// value of the wrong type falls back to the default and a font size outside
  /// the supported range is clamped, so bad data cannot reach the slider or the
  /// reader's stylesheet.
  factory ReaderSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReaderSettings();

    final themeMode = json['themeMode'];
    final fontFamily = json['fontFamily'];
    final fontSize = json['fontSize'];

    return ReaderSettings(
      themeMode: ReaderThemeMode.fromName(
        themeMode is String ? themeMode : null,
      ),
      fontFamily: fontFamily is String && fontFamily.isNotEmpty
          ? fontFamily
          : kDefaultFontFamily,
      fontSize: fontSize is num
          ? fontSize.toDouble().clamp(kMinFontSize, kMaxFontSize)
          : kDefaultFontSize,
    );
  }

  static const String kDefaultFontFamily = 'System';
  static const double kDefaultFontSize = 17;
  static const double kMinFontSize = 12;
  static const double kMaxFontSize = 28;
  static const double kFontSizeStep = 1.0;

  final ReaderThemeMode themeMode;
  final String fontFamily;
  final double fontSize;

  bool get isSystemFont => fontFamily == kDefaultFontFamily;

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
  };

  ReaderSettings copyWith({
    ReaderThemeMode? themeMode,
    String? fontFamily,
    double? fontSize,
  }) {
    return ReaderSettings(
      themeMode: themeMode ?? this.themeMode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}
