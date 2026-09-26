import 'package:get/get.dart';

import '../../app_shell.dart';
import '../../features/account/bindings/account_binding.dart';
import '../../features/account/views/login_page.dart';
import '../../features/article/bindings/article_binding.dart';
import '../../features/article/views/article_page.dart';
import '../../features/favorites/bindings/favorites_binding.dart';
import '../../features/home/bindings/home_binding.dart';
import '../../features/settings/bindings/settings_binding.dart';
import 'app_routes.dart';

abstract final class AppPages {
  /// Library and Settings are tabs inside the shell, so only the shell itself
  /// needs bindings for all three features.
  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.home,
      page: () => const AppShell(),
      bindings: [HomeBinding(), FavoritesBinding(), SettingsBinding()],
    ),
    GetPage(
      name: AppRoutes.article,
      page: () => const ArticlePage(),
      binding: ArticleBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: AccountBinding(),
    ),
  ];
}
