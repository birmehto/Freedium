import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app_shell.dart';
import 'core/controllers/app_controllers.dart';
import 'core/navigation/app_navigation.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_snackbar.dart';

class Freedium extends ConsumerWidget {
  const Freedium({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferredMode = ref.watch(
      themeControllerProvider.select((state) => state.preferredMode),
    );

    return MaterialApp(
      title: 'Freedium',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: AppTheme.themeMode(preferredMode),
      home: const AppShell(),
    );
  }
}
