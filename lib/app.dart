import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import 'core/routes/app_routes.dart';
import 'core/services/theme_service.dart';

class Readora extends StatelessWidget {
  const Readora({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();

    final m3eLight = M3EThemeData.light(seedColor: const Color(0xFF006A6A));

    return M3ETheme(
      data: m3eLight,
      child: GetMaterialApp(
        title: 'Readora',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF006A6A),
            surface: const Color(0xFFF8FAF9),
            primary: const Color(0xFF006A6A),
            secondary: const Color(0xFF4A6363),
            tertiary: const Color(0xFF4B6078),
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAF9),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF006A6A),
            brightness: Brightness.dark,
            surface: const Color(0xFF0A0F0F),
            primary: const Color(0xFF4DB6AC),
            secondary: const Color(0xFFB0CCCC),
            tertiary: const Color(0xFFB4C8E8),
          ),
          scaffoldBackgroundColor: const Color(0xFF0A0F0F),
        ),
        themeMode: themeService.themeMode,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.home,
        getPages: AppPages.routes,
      ),
    );
  }
}
