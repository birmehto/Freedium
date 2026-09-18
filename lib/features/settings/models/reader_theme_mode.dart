/// Reading-appearance modes applied inside the embedded reader.
enum ReaderThemeMode {
  system,
  light,
  dark,
  sepia,
  oled;

  static ReaderThemeMode fromName(String? name) {
    return ReaderThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ReaderThemeMode.system,
    );
  }

  String get label => switch (this) {
    ReaderThemeMode.system => 'System',
    ReaderThemeMode.light => 'Light',
    ReaderThemeMode.dark => 'Dark',
    ReaderThemeMode.sepia => 'Sepia',
    ReaderThemeMode.oled => 'OLED',
  };
}
