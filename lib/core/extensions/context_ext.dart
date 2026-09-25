import 'package:material_ui/material_ui.dart';

extension ContextX on BuildContext {
  // THEME
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get text => theme.textTheme;
  Brightness get brightness => theme.brightness;
  bool get isDark => brightness == Brightness.dark;
  bool get isLight => brightness == Brightness.light;

  // FOCUS & KEYBOARD
  void unfocus() {
    final FocusScopeNode current = FocusScope.of(this);
    if (!current.hasPrimaryFocus) current.unfocus();
  }

  void focus(FocusNode node) => FocusScope.of(this).requestFocus(node);
}
