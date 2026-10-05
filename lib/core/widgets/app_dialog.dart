import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// App's dialog: the single place that owns how a dialog is presented, painted
/// and dismissed.
///
/// Wraps [M3EDialog] with the pieces every call site was repeating by hand — a
/// transparent [Material] so [InkWell] and M3E button ripples have something to
/// paint ink on, and a scroll-safe body so long option lists cannot overflow.
///
/// Always present through [AppDialog.show] rather than mounting [AppDialog]
/// yourself, so every dialog shares one route and one dismissal path.
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    super.key,
    this.icon,
    this.content,
    this.contentBuilder,
    this.actions = const <Widget>[],
    this.topDivider = false,
    this.bottomDivider = false,
    this.isContentScrollable = true,
    this.maxContentHeightFactor = _defaultMaxContentHeightFactor,
  }) : assert(
         content != null || contentBuilder != null,
         'AppDialog needs content or contentBuilder.',
       ),
       assert(
         content == null || contentBuilder == null,
         'Pass content or contentBuilder, not both.',
       );

  final String title;
  final Widget? icon;

  /// Static body. Built by the caller, so it only ever sees the *caller's*
  /// context — use [AppDialog.close] to dismiss the dialog from here.
  final Widget? content;

  /// Body built inside the dialog route, which is what makes
  /// `Navigator.of(context).pop()` correct. Prefer this whenever the body can
  /// dismiss the dialog.
  final WidgetBuilder? contentBuilder;

  final List<Widget> actions;
  final bool topDivider;
  final bool bottomDivider;

  /// Caps the body and scrolls it. Leave on for anything list-shaped; turn off
  /// for short, fixed-size bodies that should not gain a scrollbar.
  final bool isContentScrollable;

  /// Body height ceiling as a fraction of the screen, so a long list yields a
  /// scroll view instead of a dialog taller than the display.
  final double maxContentHeightFactor;

  static const double _defaultMaxContentHeightFactor = 0.5;

  /// Presents the dialog and completes with the popped result.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    Widget? icon,
    Widget? content,
    WidgetBuilder? contentBuilder,
    List<Widget> actions = const <Widget>[],
    bool topDivider = false,
    bool bottomDivider = false,
    bool isContentScrollable = true,
    bool barrierDismissible = true,
    bool? resizeToAvoidBottomInset,
  }) {
    return M3EDialog.show<T>(
      context,
      barrierDismissible: barrierDismissible,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      dialog: AppDialog(
        title: title,
        icon: icon,
        content: content,
        contentBuilder: contentBuilder,
        actions: actions,
        topDivider: topDivider,
        bottomDivider: bottomDivider,
        isContentScrollable: isContentScrollable,
      ),
    );
  }

  /// Dismisses the dialog [show] opened, optionally with a [result].
  ///
  /// Targets the root navigator because that is the route [M3EDialog.show]
  /// pushes onto, so this stays correct for a [content] body that was built
  /// against a page context rather than a dialog one.
  static void close<T>(BuildContext context, [T? result]) {
    Navigator.of(context, rootNavigator: true).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      // Transparent on purpose: M3EDialog already paints the surface and the
      // level-3 shadow, so an opaque Material would stack a second one on top
      // of the M3E colours. Still needed — without it ripples have no ink host.
      type: MaterialType.transparency,
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      child: M3EDialog(
        title: title,
        icon: icon,
        content: _buildContent(context),
        actions: actions,
        topDivider: topDivider,
        bottomDivider: bottomDivider,
      ),
    );
  }

  Widget? _buildContent(BuildContext context) {
    final Widget? body = switch (contentBuilder) {
      // Builder pushes the body under the dialog route, so a pop from inside it
      // can never reach the page's navigator.
      final WidgetBuilder builder => Builder(builder: builder),
      null => content,
    };
    if (body == null) return null;
    if (!isContentScrollable) return body;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * maxContentHeightFactor,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: body,
      ),
    );
  }
}
