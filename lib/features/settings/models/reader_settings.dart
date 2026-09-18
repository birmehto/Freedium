import 'reader_theme_mode.dart';

/// Typography + appearance settings applied to the embedded reader.
class ReaderSettings {
  const ReaderSettings({
    this.themeMode = ReaderThemeMode.system,
    this.fontFamily = kDefaultFontFamily,
    this.fontSize = 17.0,
    this.lineHeight = 1.8,
    this.paragraphSpacing = 1.0,
    this.contentWidthEm = 42.0,
    this.textAlign = 'justify',
  });

  factory ReaderSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReaderSettings();
    return ReaderSettings(
      themeMode: ReaderThemeMode.fromName(json['themeMode'] as String?),
      fontFamily: json['fontFamily'] as String? ?? kDefaultFontFamily,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 17.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.8,
      paragraphSpacing: (json['paragraphSpacing'] as num?)?.toDouble() ?? 1.0,
      contentWidthEm: (json['contentWidthEm'] as num?)?.toDouble() ?? 42.0,
      textAlign: json['textAlign'] as String? ?? 'justify',
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
  final double lineHeight;
  final double paragraphSpacing;
  final double contentWidthEm;
  final String textAlign;

  bool get isSystemFont => fontFamily == kDefaultFontFamily;

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'lineHeight': lineHeight,
    'paragraphSpacing': paragraphSpacing,
    'contentWidthEm': contentWidthEm,
    'textAlign': textAlign,
  };

  ReaderSettings copyWith({
    ReaderThemeMode? themeMode,
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    double? paragraphSpacing,
    double? contentWidthEm,
    String? textAlign,
  }) {
    return ReaderSettings(
      themeMode: themeMode ?? this.themeMode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      contentWidthEm: contentWidthEm ?? this.contentWidthEm,
      textAlign: textAlign ?? this.textAlign,
    );
  }
}
