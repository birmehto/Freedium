import 'package:material_ui/material_ui.dart';

import '../animation/app_animator.dart';

/// Navigator 1.0 without a routing package: two screens, one push, one pop.
///
/// The key is attached to the root [MaterialApp], so any controller can navigate
/// without holding a [BuildContext]. It is null in pure unit tests, which simply
/// means no screen changes there.
final appNavigatorKey = GlobalKey<NavigatorState>();

Future<T?> pushPage<T extends Object?>(Widget page) {
  final navigator = appNavigatorKey.currentState;
  if (navigator == null) return Future.value();
  return navigator.push<T>(AppAnimator.pageRoute<T>(page));
}

void pop() => appNavigatorKey.currentState?.pop();
