import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import 'core/animation/app_animator.dart';
import 'core/controllers/app_shell_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/favorites/views/favorites_page.dart';
import 'features/home/views/home_page.dart';
import 'features/settings/views/settings_page.dart';

/// The three top-level tabs share one [Scaffold]: switching tabs keeps each
/// page's scroll position instead of rebuilding it.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _pages = <Widget>[HomePage(), FavoritesPage(), SettingsPage()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(appShellTabProvider);
    final index = tab.index;

    return Scaffold(
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: _TabBar(
        selected: index,
        onSelected: (i) => ref
            .read(appShellTabProvider.notifier)
            .selectTab(AppShellTab.values[i]),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  static const _items = [
    (
      label: 'Home',
      icon: LucideIcons.newspaper,
      active: LucideIcons.newspaper,
    ),
    (
      label: 'Library',
      icon: LucideIcons.library,
      active: LucideIcons.library,
    ),
    (
      label: 'Settings',
      icon: LucideIcons.settings2,
      active: LucideIcons.settings2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final rule = AppTheme.rule(context);
    final muted = AppTheme.muted(context);
    final accent = AppTheme.accent(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paper(context),
        border: Border(top: BorderSide(color: rule, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _TabItem(
                    item: _items[i],
                    active: selected == i,
                    muted: muted,
                    accent: accent,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.item,
    required this.active,
    required this.muted,
    required this.accent,
    required this.onTap,
  });

  final ({String label, IconData icon, IconData active}) item;
  final bool active;
  final Color muted;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.ink(context) : muted;
    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(active ? item.active : item.icon, size: 21, color: color),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: AppAnimator.fast,
            curve: AppAnimator.curve,
            width: active ? 16 : 0,
            height: 2,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
