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

      final m3eTheme = isDark
          ? M3EThemeData.dark(seedColor: seedColor)
          : M3EThemeData.light(seedColor: seedColor);

      final flutterTheme = fm.ThemeData(
        useMaterial3: true,
        colorScheme: fm.ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: isDark ? fm.Brightness.dark : fm.Brightness.light,
        ),
      );

      return M3ETheme(
        data: m3eTheme,
        child: GetMaterialApp(
          title: 'Freedium',
          theme: flutterTheme,
          darkTheme: flutterTheme,
          themeMode: isDark ? fm.ThemeMode.dark : fm.ThemeMode.light,
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
