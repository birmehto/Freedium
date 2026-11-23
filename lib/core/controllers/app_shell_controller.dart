import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppShellTab { home, library, settings }

final appShellTabProvider =
    NotifierProvider<AppShellController, AppShellTab>(AppShellController.new);

class AppShellController extends Notifier<AppShellTab> {
  @override
  AppShellTab build() => AppShellTab.home;

  void selectTab(AppShellTab tab) => state = tab;
}
