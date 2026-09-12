import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as ui;

import 'core/routes/app_routes.dart';
import 'core/services/theme_service.dart';

class Readora extends StatelessWidget {
  const Readora({super.key});

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
        data: m3eTheme,
        child: GetMaterialApp(
          title: 'Readora',
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Inter',
            colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Inter',
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
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
