import 'package:get/get.dart';

import '../../app_shell.dart';
import '../../features/article/views/article_page.dart';
import '../../features/favorites/bindings/favorites_binding.dart';
import '../../features/home/bindings/home_binding.dart';
import '../../features/settings/bindings/settings_binding.dart';
import '../../features/support/bindings/support_binding.dart';
import '../bindings/shell_binding.dart';
import 'app_routes.dart';

abstract final class AppPages {
  /// Library and Settings are tabs inside the shell, so only the shell itself
  /// needs bindings for all three features.
  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.home,
      page: () => const AppShell(),
      bindings: [
        ShellBinding(),
        HomeBinding(),
        FavoritesBinding(),
        SettingsBinding(),
        SupportBinding(),
      ],
    ),
    GetPage(
      name: AppRoutes.article,
      // No binding: the page owns its own controller, so a second reader cannot
      // inherit — or lose — the first one's.
      page: () => const ArticlePage(),
    ),
  ];
}
