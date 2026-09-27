import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'core/controllers/app_shell_controller.dart';
import 'features/favorites/views/favorites_page.dart';
import 'features/home/views/home_page.dart';
import 'features/settings/views/settings_page.dart';

/// Root shell: top-level navigation via a bottom navigation bar.
///
/// Stateless: the selected tab belongs to [AppShellController], which also
/// refreshes a tab's stored data when it comes forward.
class AppShell extends GetView<AppShellController> {
  const AppShell({super.key});

  /// One entry per [AppShellTab], in the same order.
  static const List<Widget> _pages = [
    HomePage(),
    FavoritesPage(),
    SettingsPage(),
  ];

  static const List<({String label, IconData icon, IconData? selectedIcon})>
  _destinations = [
    (label: 'Home', icon: M3EIcons.home, selectedIcon: M3EIcons.home_filled),
    (label: 'Library', icon: M3EIcons.auto_stories_rounded, selectedIcon: null),
    (label: 'Settings', icon: M3EIcons.settings, selectedIcon: null),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.tab.value.index;

      return Scaffold(
        // The children are const, so a tab switch reuses their elements and
        // each tab keeps its scroll position and text fields.
        body: IndexedStack(index: index, children: _pages),
        bottomNavigationBar: M3ENavigationBar(
          // Labels are always shown: this bar has only three destinations, and
          // the icon alone does not say what "Library" holds. Pinned rather than
          // left to the package default so a default change cannot silently
          // drop every label.
          // ignore: avoid_redundant_argument_values
          labelBehavior: M3ENavBarLabelBehavior.alwaysShow,
          destinations: [
            for (final destination in _destinations)
              M3ENavigationBarDestination(
                icon: Icon(destination.icon),
                selectedIcon: destination.selectedIcon == null
                    ? null
                    : Icon(destination.selectedIcon),
                label: destination.label,
              ),
          ],
          selectedIndex: index,
          onDestinationSelected: (i) =>
              controller.selectTab(AppShellTab.values[i]),
        ),
      );
    });
  }
}
