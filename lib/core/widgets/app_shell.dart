import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/favorites/views/favorites_page.dart';
import '../../features/home/views/home_page.dart';
import '../../features/settings/views/settings_page.dart';

/// Root shell: expressive app bar + tab content + navigation bar.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const List<String> _titles = ['Readora', 'Favorites', 'Settings'];

  static const List<M3ENavigationBarDestination> _destinations = [
    M3ENavigationBarDestination(icon: Icon(M3EIcons.home), label: 'Home'),
    M3ENavigationBarDestination(
      icon: Icon(M3EIcons.favorite),
      label: 'Favorites',
    ),
    M3ENavigationBarDestination(
      icon: Icon(M3EIcons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);

    return Scaffold(
      body: ColoredBox(
        color: theme.colorScheme.surface,
        child: Column(
          children: [
            M3EAppBar.top(titleText: _titles[_index], centerTitle: true),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [HomePage(), FavoritesPage(), SettingsPage()],
              ),
            ),
            M3ENavigationBar(
              destinations: _destinations,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
            ),
          ],
        ),
      ),
    );
  }
}
