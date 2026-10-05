import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/services/share_intent_service.dart';
import 'package:freedium/core/storage/preferences_store.dart';

import '../../helpers/test_env.dart';

/// The plugin's platform channel does not exist outside a device, so the
/// service's platform entry point is exercised through [ShareIntentService
/// .handleShare] — the single place a share payload is interpreted, for both
/// the launch intent and the live stream.
void main() {
  group('ShareIntentService', () {
    const article = 'https://medium.com/@user/shared-post';
    const other = 'https://medium.com/@user/another-post';

    late PreferencesStore preferences;
    late ShareIntentService service;

    setUp(() {
      final storage = createTestStorage();
      preferences = storage.preferences;
      service = ShareIntentService(preferences);
    });

    /// A fresh service over the same store, standing in for a new process.
    ShareIntentService relaunch() => ShareIntentService(preferences);

    test('publishes a newly shared URL', () {
      service.handleShare(article);

      expect(service.incomingUrl.value, article);
      expect(preferences.lastSharedUrl, article);
    });

    test('finds the URL inside a share payload that is mostly prose', () {
      service.handleShare('Read this later: $article — worth it.');

      expect(service.incomingUrl.value, article);
    });

    test('ignores a payload with no URL in it', () {
      service.handleShare('just some text with no link at all');

      expect(service.incomingUrl.value, isNull);
      expect(preferences.lastSharedUrl, isNull);
    });

    test('ignores a share that is not a link', () {
      service.handleShare('mailto:someone@example.com');

      expect(service.incomingUrl.value, isNull);
    });

    // The bug this guards: Android keeps the intent that started a task on that
    // task and hands it back as the "initial" intent on every relaunch, so
    // coming back to the app re-opened the article instead of showing Home.
    test('a re-delivered launch intent does not re-open the article', () {
      service.handleShare(article);
      expect(service.incomingUrl.value, article);

      service.consume();
      expect(service.incomingUrl.value, isNull);

      final restarted = relaunch();
      restarted.handleShare(article);

      expect(
        restarted.incomingUrl.value,
        isNull,
        reason: 'reopening the app must land on Home, not back in the reader',
      );
    });

    test('a different article after a re-delivery is still opened', () {
      service.handleShare(article);
      service.consume();

      final restarted = relaunch();
      restarted.handleShare(other);

      expect(restarted.incomingUrl.value, other);
    });

    test('the same article shared again once the share is forgotten', () {
      service.handleShare(article);
      service.consume();

      preferences.forgetLastShare();
      service.handleShare(article);

      expect(service.incomingUrl.value, article);
    });

    test('consume clears the field but keeps the record', () {
      service.handleShare(article);
      service.consume();

      expect(service.incomingUrl.value, isNull);
      expect(
        preferences.lastSharedUrl,
        article,
        reason: 'the record has to outlive the field, or the next launch is '
            'mistaken for a new share',
      );
    });
  });

  group('PreferencesStore share record', () {
    test('round-trips the last shared URL', () {
      final preferences = createTestStorage().preferences;

      expect(preferences.lastSharedUrl, isNull);

      preferences.lastSharedUrl = 'https://medium.com/@user/a-post';
      expect(preferences.lastSharedUrl, 'https://medium.com/@user/a-post');

      preferences.forgetLastShare();
      expect(preferences.lastSharedUrl, isNull);
    });

    test('assigning null clears the record', () {
      final preferences = createTestStorage().preferences;

      preferences.lastSharedUrl = 'https://medium.com/@user/a-post';
      preferences.lastSharedUrl = null;

      expect(preferences.lastSharedUrl, isNull);
    });
  });
}
