import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// The whole app's one snackbar.
///
/// Every transient message travels through [AppSnackbar.show], so a message
/// is always presented, painted and dismissed the same way — with M3E's
/// [M3ESnackbar] over the app's overlay. Call sites never touch [M3ESnackbar]
/// (or a scaffold messenger) directly.
///
/// Controllers hand it `Get.context` — the navigator context a controller owns
/// for its whole life, and the only context a view-less flow has. M3E presents
/// into the root overlay, which only resolves from a context *inside* one of
/// its entries, and the navigator sits above all of them; finding a context
/// that can actually present is therefore this wrapper's job, not the call
/// site's.
abstract final class AppSnackbar {
  /// Shows [message] over the app.
  ///
  /// Silent when no presenting context can be resolved: a message raised with
  /// a null or unmounted context — or by a test harness without an app shell —
  /// degrades to nothing rather than crashing the code that asked for it.
  ///
  /// One message at a time: the latest replaces whatever is showing, so a
  /// burst of callbacks does not queue a wall of bars.
  static void show(BuildContext? context, {required String message}) {
    final ctx = _presentable(context);
    if (ctx == null) return;

    M3ESnackbar.show(ctx, message: message);
  }

  /// The first context [M3ESnackbar] can present from, or null.
  ///
  /// [context] is trusted first: a page handed in by a widget is already
  /// below the overlay. When it cannot present — the navigator context never
  /// can — the app's own contexts are descended into until one sits inside an
  /// overlay entry.
  static BuildContext? _presentable(BuildContext? context) {
    if (context != null && _canPresent(context)) return context;

    for (final root in <BuildContext>[
      if (context != null && context.mounted) context,
      if (Get.overlayContext != null && Get.overlayContext!.mounted)
        Get.overlayContext!,
      if (Get.context != null && Get.context!.mounted) Get.context!,
    ]) {
      final found = _descend(root, _canPresent);
      if (found != null) return found;
    }

    return null;
  }

  /// Whether [context] can resolve the root overlay M3E presents into.
  static bool _canPresent(BuildContext context) =>
      context.mounted && Overlay.maybeOf(context, rootOverlay: true) != null;

  /// The first element at or below [root] that [accept] takes, or null.
  ///
  /// Breadth does not matter here: an overlay entry sits a handful of levels
  /// under the contexts this walks, and the walk stops at the first of them.
  static BuildContext? _descend(
    BuildContext root,
    bool Function(BuildContext) accept,
  ) {
    if (!root.mounted) return null;
    if (accept(root)) return root;

    BuildContext? found;
    root.visitChildElements((child) {
      found ??= _descend(child, accept);
    });
    return found;
  }
}
