import 'package:flutter/foundation.dart';

/// Severity of a log message.
enum LogLevel { debug, info, warning, error }

/// ANSI color codes for console output (only visible in debug terminals).
class _LogColor {
  static const reset = '\x1B[0m';
  static const green = '\x1B[32m';
  static const cyan = '\x1B[36m';
  static const yellow = '\x1B[33m';
  static const red = '\x1B[31m';
}

/// Global app logging helper.
///
/// Prints structured, colorized logs in debug mode only and is automatically
/// disabled in release builds. Use [level] to convey severity and [name] to
/// tag a log with its origin (e.g. `Resolver`, `Reader`, `Storage`).
///
/// Never log sensitive data (credentials, private article URLs, user content)
/// unless strictly necessary.
void appLog(
  String message, {
  String name = 'APP',
  LogLevel level = LogLevel.debug,
}) {
  if (!kDebugMode) return;

  final color = switch (level) {
    LogLevel.debug => _LogColor.green,
    LogLevel.info => _LogColor.cyan,
    LogLevel.warning => _LogColor.yellow,
    LogLevel.error => _LogColor.red,
  };

  // ignore: avoid_print
  print('$color[$name] [${level.name}] $message${_LogColor.reset}');
}

/// Logs a debug-level message.
void appDebug(String message, {String name = 'APP'}) =>
    appLog(message, name: name);

/// Logs an informational message.
void appInfo(String message, {String name = 'APP'}) =>
    appLog(message, name: name, level: LogLevel.info);

/// Logs a warning message.
void appWarn(String message, {String name = 'APP'}) =>
    appLog(message, name: name, level: LogLevel.warning);

/// Logs an error message.
void appError(String message, {String name = 'APP'}) =>
    appLog(message, name: name, level: LogLevel.error);
