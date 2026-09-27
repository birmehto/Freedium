import 'dart:async';

import 'package:get/get.dart';

import '../../features/favorites/controllers/favorites_controller.dart';
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
  /// Re-selecting the visible tab refreshes it too: the library and the reader
  /// share the same stored reading positions, so a position written by the
  /// reader is only picked up when the library is opened again.
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
        if (Get.isRegistered<FavoritesController>()) {
          unawaited(Get.find<FavoritesController>().refreshContinueReading());
        }
      case AppShellTab.settings:
        if (Get.isRegistered<SettingsController>()) {
          Get.find<SettingsController>().syncReaderSettings();
        }
      case AppShellTab.home:
        break;
    }
  }
}
