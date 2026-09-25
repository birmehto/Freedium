import 'package:flutter/material.dart' as fm;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as ui;

import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/services/theme_service.dart';

class Freedium extends StatelessWidget {
  const Freedium({super.key});

  static const seedColor = fm.Color(0xFF00695C);

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();

    return Obx(() {
      final isDark = themeService.isDarkMode.value;

      return M3ETheme(
        data: isDark
            ? M3EThemeData.dark(seedColor: seedColor)
            : M3EThemeData.light(seedColor: seedColor),
        child: GetMaterialApp(
          title: 'Freedium',
          // Light and dark are separate themes, and `themeMode` keeps the
          // `system` preference working instead of pinning the resolved value.
          theme: _materialTheme(Brightness.light),
          darkTheme: _materialTheme(Brightness.dark),
          themeMode: themeService.themeMode,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            ui.DefaultMaterialLocalizations.delegate,
          ],
          initialRoute: AppRoutes.home,
          getPages: AppPages.routes,
        ),
      );
    });
  }

  static fm.ThemeData _materialTheme(fm.Brightness brightness) => fm.ThemeData(
    useMaterial3: true,
    colorScheme: fm.ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ),
  );
}
