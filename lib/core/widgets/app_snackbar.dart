import 'package:material_ui/material_ui.dart';

/// The whole app's one snackbar.
///
/// Every transient message travels through [AppSnackbar.show], so a message
/// is always presented, painted and dismissed the same way — with Flutter's
/// own [SnackBar] on the nearest [ScaffoldMessenger]. Call sites never touch
/// `SnackBar` (or an old overlay-style presenter) directly.
///
/// Controllers hand it `Get.context` — the navigator context a controller owns
/// for its whole life, and the only context a view-less flow has. Resolving
/// the messenger here (instead of at the call site) is exactly what keeps the
/// one-look, one-path promise true.
abstract final class AppSnackbar {
  /// Shows [message] on the scaffold nearest [context].
  ///
  /// Silent when [context] is null, no longer mounted, or has no
  /// `ScaffoldMessenger` ancestor: a message raised as its page disappears —
  /// or by a test harness without an app shell — degrades to nothing rather
  /// than crashing the code that asked for it.
  ///
  /// One message at a time: the latest replaces whatever is showing, so a
  /// burst of callbacks does not queue a wall of bars.
  static void show(BuildContext? context, {required String message}) {
    final ctx = context;
    if (ctx == null || !ctx.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(ctx);
    if (messenger == null) {
      // ignore: avoid_print
      print('DEBUG: messenger is null for context: $ctx');
      return;
    }

    try {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    } catch (e, st) {
      // ignore: avoid_print
      print('DEBUG: showSnackBar threw: $e\n$st');
    }
  }
}
