import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Severity of a log message.
enum LogLevel {
  debug(500),
  info(800),
  warning(1000),
  error(2000);

  const LogLevel(this._severity);

  final int _severity;
}

/// Global app logging helper.
///
/// Emits structured records that are silenced in release builds and tagged with
/// the subsystem [name] (e.g. `Reader`, `Storage`, `ShareIntent`).
///
/// Never log sensitive data (credentials, private article URLs, user content)
/// unless strictly necessary.
///
/// [force] emits the record even in a release build. It exists for the reader's
/// scroll diagnostics, which are the only way to see why a WebView is refusing
/// to scroll on a user's device — a fault that reproduces only in release, so
/// a build that silences its own logs cannot be diagnosed at all.
void appLog(
  String message, {
  String name = 'APP',
  LogLevel level = LogLevel.debug,
  bool force = false,
}) {
  if (!kDebugMode && !force) return;

  developer.log(
    message,
    name: name,
    level: level._severity,
    time: DateTime.now(),
  );
}
