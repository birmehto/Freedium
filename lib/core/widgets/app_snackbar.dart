import 'package:material_ui/material_ui.dart';

/// Root messenger, attached to [MaterialApp.scaffoldMessengerKey] so controllers
/// can show a message without holding a [BuildContext].
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class AppSnackbar {
  const AppSnackbar._();

  /// Shows a short floating message. Falls back to the root messenger when no
  /// context is available (e.g. from a controller).
  static void show(BuildContext? context, {required String message}) {
    final messenger = context != null && context.mounted
        ? ScaffoldMessenger.maybeOf(context)
        : rootScaffoldMessengerKey.currentState;
    messenger?.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  static void message(String message) => show(null, message: message);
}
