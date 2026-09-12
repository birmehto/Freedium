import 'package:get/get.dart';

import '../../core/widgets/app_shell.dart';
import '../../features/article/bindings/article_binding.dart';
import '../../features/article/views/article_page.dart';
import '../../features/favorites/bindings/favorites_binding.dart';
import '../../features/favorites/views/favorites_page.dart';
import '../../features/home/bindings/home_binding.dart';

import '../../features/settings/bindings/settings_binding.dart';
import '../../features/settings/views/settings_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String article = '/article';
  static const String favorites = '/favorites';
  static const String settings = '/settings';
}

class AppPages {
  static final routes = [
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
      name: AppRoutes.favorites,
      page: () => const FavoritesPage(),
      binding: FavoritesBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
    ),
  ];
}
