import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// Default top app bar used across the app.
///
/// Takes a [Widget] rather than a string so a screen can pass reactive content
/// (an `Obx`, for example) as its title.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    required this.title,
    super.key,
    this.centerTitle = true,
    this.actions,
    this.automaticallyImplyLeading = false,
  });

  final Widget title;
  final bool centerTitle;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(65);

  @override
  Widget build(BuildContext context) {
    return M3EAppBar.top(
      title: DefaultTextStyle.merge(
        style: const TextStyle(fontWeight: FontWeight.bold),
        child: title,
      ),
      centerTitle: centerTitle,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
}
