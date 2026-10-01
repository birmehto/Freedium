import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'core/controllers/app_shell_controller.dart';
import 'features/favorites/views/favorites_page.dart';
import 'features/home/views/home_page.dart';
import 'features/settings/views/settings_page.dart';

/// Root shell: top-level navigation via a bottom navigation bar.
///
/// Stateless: the selected tab belongs to [AppShellController].
class AppShell extends GetView<AppShellController> {
  const AppShell({super.key});

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
        body: IndexedStack(index: index, children: _pages),
        bottomNavigationBar: M3ENavigationBar(
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
          onDestinationSelected: (i) {
            controller.selectTab(AppShellTab.values[i]);
          },
        ),
      );
    });
  }
}
