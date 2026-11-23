import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// The app's single motion language.
///
/// Every animated transition — route pushes, tab swaps, state changes and
/// small confirmations — comes from this class, so timing never drifts between
/// screens and a low-motion device has one place to turn it down.
abstract final class AppAnimator {
  /// Quick feedback for a control the reader just touched.
  static const Duration fast = Duration(milliseconds: 160);

  /// Default duration for a screen or a state swap.
  static const Duration normal = Duration(milliseconds: 280);

  /// Deliberate, slightly slower motion for larger panels.
  static const Duration slow = Duration(milliseconds: 420);

  /// Shared easing: quick to leave, gentle to settle.
  static const Curve curve = Curves.easeOutCubic;

  /// The page route every pushed screen uses.
  ///
  /// A short lift-and-fade reads as moving forward without the horizontal
  /// slide that fights a WebView's own scroll gestures on Android.
  static Route<T> pageRoute<T>(Widget page) => PageRouteBuilder<T>(
    pageBuilder: (_, _, _) => page,
    transitionDuration: normal,
    reverseTransitionDuration: fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final eased = CurvedAnimation(parent: animation, curve: curve);
      final lift = Tween<Offset>(
        begin: const Offset(0, 0.035),
        end: Offset.zero,
      ).animate(eased);

      return SlideTransition(
        position: lift,
        child: FadeTransition(opacity: eased, child: child),
      );
    },
  );

  /// Cross-fades one widget for another, e.g. when the visible tab changes.
  static Widget switcher({
    required Object key,
    required Widget child,
    Duration duration = normal,
  }) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (widget, animation) =>
          FadeTransition(opacity: animation, child: widget),
      child: KeyedSubtree(key: ValueKey(key), child: child),
    );
  }

  /// Brings a newly mounted widget in with a quiet fade and lift.
  static Widget entrance({
    required Widget child,
    Duration delay = Duration.zero,
  }) => _AppEntrance(delay: delay, child: child);

  /// A short scale-and-fade pulse when [value] changes.
  ///
  /// Used for toggles such as saving an article: the control itself stays put,
  /// so the animation cannot shift a tap target.
  static Widget pulse({required Object value, required Widget child}) =>
      _AppPulse(key: ValueKey(value), child: child);
}

class _AppEntrance extends StatefulWidget {
  const _AppEntrance({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_AppEntrance> createState() => _AppEntranceState();
}

class _AppEntranceState extends State<_AppEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppAnimator.normal,
  );

  Timer? _delay;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      // A cancellable timer keeps a delayed entrance from outliving its
      // widget (and from leaving a pending timer behind when a screen closes).
      _delay = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eased = CurvedAnimation(
      parent: _controller,
      curve: AppAnimator.curve,
    );
    final lift = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(eased);

    return FadeTransition(
      opacity: eased,
      child: SlideTransition(position: lift, child: widget.child),
    );
  }
}

class _AppPulse extends StatelessWidget {
  const _AppPulse({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.82, end: 1),
      duration: AppAnimator.fast,
      curve: AppAnimator.curve,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}
