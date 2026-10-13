/// Shared spacing scale.
///
/// Screen-level gaps should come from here so padding stays consistent across
/// Home, Library, Settings, dialogs and bottom sheets. Values that exist for a
/// genuine design reason (icon geometry, optical alignment) may stay literal.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Bottom breathing room for scrollable content sitting above a navigation
  /// bar or a floating action button.
  static const double scrollEnd = 64;
}

/// Corner radii used by cards, sheets, fields and badges.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;

  /// Fully rounded shape, used for pills and drag handles.
  static const double full = 999;
}
