// ignore_for_file: deprecated_member_use

import 'package:material_ui/material_ui.dart';

extension ContextX on BuildContext {
  // THEME
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get text => theme.textTheme;
  Brightness get brightness => theme.brightness;
  bool get isDark => brightness == Brightness.dark;
  bool get isLight => brightness == Brightness.light;

  // SNACKBARS (Safe)

  void snack(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? bg,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          action: action,
          backgroundColor: bg,
        ),
      );
  }

  // FOCUS & KEYBOARD
  void unfocus() {
    final FocusScopeNode current = FocusScope.of(this);
    if (!current.hasPrimaryFocus) current.unfocus();
  }

  void focus(FocusNode node) => FocusScope.of(this).requestFocus(node);
}
