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

  // MEDIA QUERY (Safe access)

  MediaQueryData get mq =>
      MediaQuery.maybeOf(this) ?? MediaQueryData.fromView(View.of(this));

  Size get size => mq.size;
  double get width => size.width;
  double get height => size.height;
  double get textScale => mq.textScaleFactor;

  EdgeInsets get padding => mq.padding;
  EdgeInsets get insets => mq.viewInsets;
  double get devicePixelRatio => mq.devicePixelRatio;

  bool get isKeyboardOpen => insets.bottom > 0;

  // RESPONSIVE

  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  bool get isMobile => width < mobileMax;
  bool get isTablet => width >= mobileMax && width < tabletMax;
  bool get isDesktop => width >= tabletMax;

  // ORIENTATION

  bool get isPortrait => mq.orientation == Orientation.portrait;
  bool get isLandscape => mq.orientation == Orientation.landscape;

  // SAFE AREA

  double get statusBar => padding.top;
  double get bottomBar => padding.bottom;
  double get safeHeight => height - statusBar - bottomBar;

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

  void errorSnack(String message) {
    snack(message, bg: colors.errorContainer);
  }

  void successSnack(String message) {
    snack(message, bg: colors.primaryContainer);
  }

  // FOCUS & KEYBOARD
  void unfocus() {
    final FocusScopeNode current = FocusScope.of(this);
    if (!current.hasPrimaryFocus) current.unfocus();
  }

  void focus(FocusNode node) => FocusScope.of(this).requestFocus(node);
}
