import 'package:material_ui/material_ui.dart';

class AppTheme {
  static const seedColor = Color(0xFF006A6A);

  static final lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      surface: const Color(0xFFF8FAF9),
      primary: seedColor,
      secondary: const Color(0xFF4A6363),
      tertiary: const Color(0xFF4B6078),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAF9),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF0A0F0F),
      primary: const Color(0xFF4DB6AC),
      secondary: const Color(0xFFB0CCCC),
      tertiary: const Color(0xFFB4C8E8),
    ),
    scaffoldBackgroundColor: const Color(0xFF0A0F0F),
  );
}
