import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/config/mirror_source.dart';
import 'package:freedium/core/network/article_resolver.dart';

void main() {
  late ArticleResolver resolver;

  setUp(() {
    resolver = ArticleResolver(
      sources: [
        MirrorSource(
          id: 'mirror-a',
          name: 'Mirror A',
          url: 'https://a.example/',
          urlTemplate: 'https://a.example/{original}',
        ),
        MirrorSource(
          id: 'mirror-b',
          name: 'Mirror B',
          url: 'https://b.example/',
          urlTemplate: 'https://b.example/{original}',
        ),
      ],
    );
  });

  group('ArticleResolver', () {
    test('resolve returns the first healthy mirror URL', () {
      final url = resolver.resolve('https://medium.com/@u/1');
      expect(url, 'https://a.example/https%3A%2F%2Fmedium.com%2F%40u%2F1');
      expect(resolver.lastSourceId, 'mirror-a');
    });

    test('preferred source is attempted first', () {
      resolver.setPreferred('mirror-b');
      final url = resolver.resolve('https://medium.com/@u/2');
      expect(url, 'https://b.example/https%3A%2F%2Fmedium.com%2F%40u%2F2');
    });

    test('is Medium URL encoded into the mirror template', () {
      final url = resolver.resolve('https://medium.com/@u/3?utm_source=x&a=1');
      // Tracking params are stripped, then URL-encoded into the template
      expect(
        url,
        'https://a.example/https%3A%2F%2Fmedium.com%2F%40u%2F3%3Fa%3D1',
      );
    });

    test('failure flips availability after three consecutive failures', () {
      resolver.resolve('https://medium.com/@u/4');
      resolver.reportFailure('mirror-a');
      resolver.reportFailure('mirror-a');
      expect(
        resolver.sources.firstWhere((s) => s.id == 'mirror-a').available,
        isTrue,
      );
      resolver.reportFailure('mirror-a');
      expect(
        resolver.sources.firstWhere((s) => s.id == 'mirror-a').available,
        isFalse,
      );
    });

    test('fallback skips an unhealthy mirror', () {
      resolver.resolve('https://medium.com/@u/5');
      resolver.reportSuccess('mirror-a');
      resolver.reportFailure('mirror-a');
      resolver.reportFailure('mirror-a');
      resolver.reportFailure('mirror-a');

      final next = resolver.nextFallback();
      expect(next, 'https://b.example/https%3A%2F%2Fmedium.com%2F%40u%2F5');
      expect(resolver.lastSourceId, 'mirror-b');
    });

    test('nextFallback returns null when auto fallback is disabled', () {
      resolver.autoFallback = false;
      resolver.setPreferred('mirror-b');
      resolver.resolve('https://medium.com/@u/6');
      // primary failed but auto-fallback is off; same source is re-tried
      expect(resolver.nextFallback(), isNull);
    });

    test('reportSuccess restores availability', () {
      resolver.resolve('https://medium.com/@u/7');
      resolver.reportFailure('mirror-a');
      resolver.reportFailure('mirror-a');
      resolver.reportFailure('mirror-a');
      final src = resolver.sources.firstWhere((s) => s.id == 'mirror-a');
      expect(src.available, isFalse);

      resolver.reportSuccess('mirror-a');
      expect(src.available, isTrue);
      expect(src.consecutiveFailures, 0);
    });

    test('proxiedUrls lists healthy mirrors before unhealthy ones', () {
      resolver.resolve('https://medium.com/@u/8');
      resolver.reportFailure('mirror-a');
      resolver.reportFailure('mirror-a');
      resolver.reportFailure('mirror-a');

      final urls = resolver.proxiedUrls('https://medium.com/@u/8');
      expect(urls, hasLength(2));
      expect(resolver.lastSourceId, isNotNull);
    });

    test('catalogue defaults include freedium and textise', () {
      final ids = MirrorCatalog.defaults.map((s) => s.id).toList();
      expect(ids, containsAll(['freedium', 'textise']));
    });
  });
}
