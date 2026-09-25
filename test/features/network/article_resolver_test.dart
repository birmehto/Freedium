import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/config/mirror_source.dart';
import 'package:freedium/core/network/article_resolver.dart';

MirrorSource mirror(String id) => MirrorSource(
  id: id,
  name: 'Mirror $id',
  url: 'https://$id.example/',
  urlTemplate: 'https://$id.example/{original}',
);

void main() {
  late ArticleResolver resolver;

  setUp(() {
    resolver = ArticleResolver(
      sources: [mirror('mirror-a'), mirror('mirror-b')],
    );
  });

  /// Takes [id] out of rotation, as three consecutive failures would.
  void exhaust(String id) {
    resolver.reportFailure(id);
    resolver.reportFailure(id);
    resolver.reportFailure(id);
  }

  group('resolve', () {
    test('returns the first healthy mirror URL', () {
      final url = resolver.resolve('https://medium.com/@u/1');
      expect(
        url,
        'https://mirror-a.example/https%3A%2F%2Fmedium.com%2F%40u%2F1',
      );
      expect(resolver.lastSourceId, 'mirror-a');
    });

    test('preferred source is attempted first', () {
      resolver.setPreferred('mirror-b');
      expect(
        resolver.resolve('https://medium.com/@u/2'),
        'https://mirror-b.example/https%3A%2F%2Fmedium.com%2F%40u%2F2',
      );
    });

    test('an exhausted preferred source falls through to a healthy one', () {
      resolver.setPreferred('mirror-b');
      exhaust('mirror-b');

      expect(
        resolver.resolve('https://medium.com/@u/3'),
        startsWith('https://mirror-a.example/'),
      );
      expect(resolver.lastSourceId, 'mirror-a');
    });

    test('strips tracking params before proxying', () {
      expect(
        resolver.resolve('https://medium.com/@u/3?utm_source=x&a=1'),
        'https://mirror-a.example/https%3A%2F%2Fmedium.com%2F%40u%2F3%3Fa%3D1',
      );
    });

    test('returns null for an unusable article URL', () {
      expect(resolver.resolve('not a url'), isNull);
      expect(resolver.lastSourceId, isNull);
    });

    test('still resolves when the whole catalog is unhealthy', () {
      exhaust('mirror-a');
      exhaust('mirror-b');

      expect(resolver.resolve('https://medium.com/@u/4'), isNotNull);
    });
  });

  group('health tracking', () {
    test('a mirror leaves rotation after three consecutive failures', () {
      resolver.resolve('https://medium.com/@u/4');

      resolver.reportFailure();
      resolver.reportFailure();
      expect(resolver.sources.first.available, isTrue);

      resolver.reportFailure();
      expect(resolver.sources.first.available, isFalse);
    });

    test('reportSuccess restores availability', () {
      resolver.resolve('https://medium.com/@u/7');
      exhaust('mirror-a');
      expect(resolver.sources.first.available, isFalse);

      resolver.reportSuccess('mirror-a');
      expect(resolver.sources.first.available, isTrue);
      expect(resolver.sources.first.consecutiveFailures, 0);
    });
  });

  group('nextFallback', () {
    test('skips an unhealthy mirror', () {
      resolver.resolve('https://medium.com/@u/5');
      exhaust('mirror-a');

      expect(
        resolver.nextFallback(),
        'https://mirror-b.example/https%3A%2F%2Fmedium.com%2F%40u%2F5',
      );
      expect(resolver.lastSourceId, 'mirror-b');
    });

    test('recovers when every mirror is unhealthy', () {
      resolver.resolve('https://medium.com/@u/5');
      exhaust('mirror-a');
      exhaust('mirror-b');

      expect(resolver.nextFallback(), isNotNull);
    });

    test('returns null when auto fallback is disabled', () {
      resolver.autoFallback = false;
      resolver.resolve('https://medium.com/@u/6');

      expect(resolver.nextFallback(), isNull);
    });

    test('returns null when there is nothing to switch to', () {
      resolver = ArticleResolver(sources: [mirror('only')]);
      resolver.resolve('https://medium.com/@u/8');

      expect(resolver.nextFallback(), isNull);
    });
  });

  group('candidates', () {
    test('puts the preferred mirror first', () {
      resolver.setPreferred('mirror-b');
      expect(resolver.candidates.map((s) => s.id), ['mirror-b', 'mirror-a']);
    });

    test('keeps catalog order without a preference', () {
      expect(resolver.candidates.map((s) => s.id), ['mirror-a', 'mirror-b']);
    });
  });

  group('isolation', () {
    test('each resolver gets its own mirror instances', () {
      final other = ArticleResolver();
      final url = resolver.resolve('https://medium.com/@u/9');
      expect(url, isNotNull);

      // Health tracked here must not be visible to a different resolver.
      exhaust('freedium');
      expect(
        other.resolve('https://medium.com/@u/9'),
        startsWith('https://freedium-mirror.cfd/'),
      );
    });
  });

  group('MirrorCatalog', () {
    test('defaults include freedium and textise', () {
      final ids = MirrorCatalog.createDefaults().map((s) => s.id).toList();
      expect(ids, containsAll(['freedium', 'textise']));
    });

    test('returns a fresh list on every call', () {
      final first = MirrorCatalog.createDefaults().first;
      first.recordFailure();
      first.recordFailure();
      first.recordFailure();

      expect(MirrorCatalog.createDefaults().first.available, isTrue);
    });
  });
}
