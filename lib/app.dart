import 'package:flutter/material.dart' as fm;
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as ui;
import 'package:material_ui/material_ui.dart';

import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/services/theme_service.dart';

class Freedium extends StatefulWidget {
  const Freedium({super.key});

  @override
  State<Freedium> createState() => _FreediumState();
}

class _FreediumState extends State<Freedium> {
  static const seedColor = Color(0xFF00695C);

  final M3EThemeController _themeController = M3EThemeController();

  ThemeService get _themeService => Get.find<ThemeService>();

  @override
  void initState() {
    super.initState();
    _syncTheme(_themeService.isDarkMode.value);
    ever(_themeService.isDarkMode, _syncTheme);
  }

  void _syncTheme(bool isDark) {
    _themeController.setBrightness(isDark ? Brightness.dark : Brightness.light);
  }

  @override
  Widget build(BuildContext context) {
    return M3ETheme(
      dynamicColoring: true,
      autoTheming: false,
      controller: _themeController,
      data: M3EThemeData.light(seedColor: seedColor),
      child: GetMaterialApp(
        title: 'Freedium',
        theme: fm.ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
          colorScheme: fm.ColorScheme.fromSeed(seedColor: seedColor),
        ),
        darkTheme: fm.ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
          colorScheme: fm.ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: fm.Brightness.dark,
          ),
        ),
        themeMode: _themeService.themeMode,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          ui.DefaultMaterialLocalizations.delegate,
        ],
        initialRoute: AppRoutes.home,
        getPages: AppPages.routes,
      ),
    );
  }
}
