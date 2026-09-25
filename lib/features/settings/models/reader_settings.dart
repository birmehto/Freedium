import 'reader_theme_mode.dart';

/// Typography + appearance settings applied to the embedded reader.
class ReaderSettings {
  const ReaderSettings({
    this.themeMode = ReaderThemeMode.system,
    this.fontFamily = kDefaultFontFamily,
    this.fontSize = 17.0,
  });

  factory ReaderSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReaderSettings();
    return ReaderSettings(
      themeMode: ReaderThemeMode.fromName(json['themeMode'] as String?),
      fontFamily: json['fontFamily'] as String? ?? kDefaultFontFamily,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 17.0,
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
    double? lineHeight,
    String? textAlign,
  }) {
    return ReaderSettings(
      themeMode: themeMode ?? this.themeMode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}
