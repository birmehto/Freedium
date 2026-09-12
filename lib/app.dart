import 'package:flutter/material.dart' as fm;
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as ui;
import 'package:material_ui/material_ui.dart';

import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/services/theme_service.dart';

class Freedium extends StatelessWidget {
  const Freedium({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    const seedColor = Color(0xFF536DFE);

    return Obx(() {
      final isDark = themeService.isDarkMode.value;
      final m3eTheme = isDark
          ? M3EThemeData.dark(seedColor: seedColor)
          : M3EThemeData.light(seedColor: seedColor);

      return M3ETheme(
        dynamicColoring: true,
        autoTheming: true,
        data: m3eTheme,
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
}
