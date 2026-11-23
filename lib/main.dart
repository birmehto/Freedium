import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/providers/service_providers.dart';
import 'core/services/clipboard_service.dart';
import 'core/services/share_intent_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // One long-lived instance per service. Providers would otherwise construct a
  // second database or a second share subscription on first watch.
  final StorageService storage;
  final ShareIntentService shareIntent;
  try {
    storage = await StorageService().init();
    shareIntent = await ShareIntentService(storage.preferences).init();
  } catch (error, stackTrace) {
    // A corrupt or unreadable database must not leave the reader staring at a
    // blank screen with no explanation.
    appLog(
      'Startup failed: $error\n$stackTrace',
      name: 'App',
      level: LogLevel.error,
    );
    runApp(const _StartupErrorApp());
    return;
  }

  // Preference writes are queued through Drift. Flushing on the way out covers
  // the last slider tick a reader made before backgrounding the app.
  AppLifecycleListener(
    onPause: () => unawaited(storage.flush()),
    onDetach: () => unawaited(storage.flush()),
  );

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        shareIntentServiceProvider.overrideWithValue(shareIntent),
        clipboardServiceProvider.overrideWithValue(ClipboardService()),
      ],
      child: const Freedium(),
    ),
  );
}

/// The smallest app that can explain a failed startup.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Freedium could not start',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your saved data could not be opened. Close the app and '
                    'try again.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.muted(context), height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
