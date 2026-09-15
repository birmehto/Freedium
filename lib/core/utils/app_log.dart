import 'package:flutter/foundation.dart';

/// ANSI color codes for console output (only visible in debug terminals)
class _LogColor {
  static const green = '\x1B[32m';
}

/// Global app logging helper.
/// Prints colorized logs in debug mode only.
/// Automatically disabled in release.
void appLog(String message, {String name = 'APP'}) {
  if (kDebugMode) {
    final formatted = '${_LogColor.green}[$name] $message${_LogColor.green}';
    // ignore: avoid_print
    print(formatted);
  }
}
