import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/article_resolver.dart';
import '../services/clipboard_service.dart';
import '../services/share_intent_service.dart';
import '../services/storage_service.dart';

/// Services are created once during startup and injected at the root of the
/// widget tree. Tests override these with prepared, in-memory instances.

/// Owns the database and the three stores. Initialized asynchronously in
/// `main()` before `runApp`, then overridden into the ProviderScope.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be overridden');
});

/// Subscribes to Android share intents during startup for the same reason.
final shareIntentServiceProvider = Provider<ShareIntentService>((ref) {
  throw UnimplementedError('shareIntentServiceProvider must be overridden');
});

/// Stateless, so Riverpod can create it on demand.
final clipboardServiceProvider = Provider<ClipboardService>(
  (ref) => ClipboardService(),
);

/// One resolver for the whole app: what one article teaches it about a mirror
/// helps the next one. Seeded from the saved preferences.
final articleResolverProvider = Provider<ArticleResolver>((ref) {
  final preferences = ref.watch(storageServiceProvider).preferences;
  final resolver = ArticleResolver();
  resolver.setPreferred(preferences.preferredMirror);
  resolver.autoFallback = preferences.autoFallback;
  return resolver;
});
