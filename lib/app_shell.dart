import 'dart:async';

import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'features/favorites/controllers/favorites_controller.dart';
import 'features/favorites/views/favorites_page.dart';
import 'features/home/views/home_page.dart';
import 'features/settings/controllers/settings_controller.dart';
import 'features/settings/views/settings_page.dart';

/// Root shell: top-level navigation via a bottom navigation bar.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const List<({IconData icon, IconData selectedIcon, String label})>
  _destinations = [
    (icon: M3EIcons.home, selectedIcon: M3EIcons.home_filled, label: 'Home'),
    (
      icon: M3EIcons.auto_stories_rounded,
      selectedIcon: M3EIcons.auto_stories_rounded,
      label: 'Library',
    ),
    (
      icon: M3EIcons.settings,
      selectedIcon: M3EIcons.settings,
      label: 'Settings',
    ),
  ];

  static const List<Widget> _pages = [
    HomePage(),
    FavoritesPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: M3ENavigationBar(
        destinations: [
          for (final d in _destinations)
            M3ENavigationBarDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          _onTabOpened(i);
        },
      ),
    );
  }

  /// Brings a tab's stored data up to date when it becomes the visible one.
  ///
  /// The reader and the library share the same stored positions, and every tab
  /// stays mounted inside the [IndexedStack], so a value read while the tab was
  /// hidden would otherwise still be on screen when the user comes back to it.
  void _onTabOpened(int index) {
    switch (index) {
      case _libraryTab:
        if (Get.isRegistered<FavoritesController>()) {
          unawaited(Get.find<FavoritesController>().refreshContinueReading());
        }
      case _settingsTab:
        if (Get.isRegistered<SettingsController>()) {
          Get.find<SettingsController>().syncReaderSettings();
        }
    }
  }

  static const int _libraryTab = 1;
  static const int _settingsTab = 2;
}
