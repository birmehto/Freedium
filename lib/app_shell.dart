import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'features/favorites/views/favorites_page.dart';
import 'features/home/views/home_page.dart';
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
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
