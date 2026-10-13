import 'package:get/get.dart';

import '../../features/settings/controllers/settings_controller.dart';

/// The top-level destinations of the root shell, in navigation-bar order.
enum AppShellTab { home, library, settings }

/// State for the root shell: which tab is showing, and bringing a tab's stored
/// data up to date when it comes forward.
///
/// The selected tab lives here rather than in the shell's `State` so that
/// [AppShell] can stay a stateless widget, and so tab switching can be tested
/// without pumping a navigation bar.
class AppShellController extends GetxController {
  final Rx<AppShellTab> tab = AppShellTab.home.obs;

  /// Shows [next] and refreshes whatever it displays.
  ///
  /// Re-selecting the visible tab refreshes it too: a reader preference changed
  /// while another tab was in front is only picked up when settings comes
  /// forward again.
  void selectTab(AppShellTab next) {
    tab.value = next;
    _onTabOpened(next);
  }

  /// Brings a tab's stored data up to date when it becomes the visible one.
  ///
  /// Every tab stays mounted inside the shell's `IndexedStack`, so a value read
  /// while the tab was hidden would otherwise still be on screen when the user
  /// comes back to it.
  void _onTabOpened(AppShellTab opened) {
    switch (opened) {
      case AppShellTab.library:
        // The library reads the favorites store directly and holds no mirrored
        // state, so a tab switch has nothing to refresh.
        break;
      case AppShellTab.settings:
        if (Get.isRegistered<SettingsController>()) {
          Get.find<SettingsController>().syncReaderSettings();
        }
      case AppShellTab.home:
        break;
    }
  }
}
