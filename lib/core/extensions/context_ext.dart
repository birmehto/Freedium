import 'package:material_ui/material_ui.dart';

/// Small, allocation-free conveniences for the theme data every screen needs.
extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colors => theme.colorScheme;

  TextTheme get text => theme.textTheme;

  /// Dismisses the software keyboard when something else should take focus.
  void unfocus() {
    final scope = FocusScope.of(this);
    if (scope.hasPrimaryFocus) scope.unfocus();
  }
}
