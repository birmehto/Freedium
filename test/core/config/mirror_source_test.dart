import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/config/mirror_source.dart';

const _article = 'https://medium.com/@user/a-post?x=1';

void main() {
  group('MirrorSource.buildUrl', () {
    test('encodes {original} as a single path or query component', () {
      final mirror = MirrorSource(
        id: 'm',
        name: 'M',
        url: 'https://m.example/',
        urlTemplate: 'https://m.example/{original}',
      );

      expect(
        mirror.buildUrl(_article),
        'https://m.example/https%3A%2F%2Fmedium.com%2F%40user%2Fa-post%3Fx%3D1',
      );
    });

    test('leaves {url} raw for prefix-style mirrors', () {
      final mirror = MirrorSource(
        id: 'm',
        name: 'M',
        url: 'https://m.example/',
        urlTemplate: 'https://m.example/newest/{url}',
      );

      expect(mirror.buildUrl(_article), 'https://m.example/newest/$_article');
    });

    test('supports both placeholders in one template', () {
      final mirror = MirrorSource(
        id: 'm',
        name: 'M',
        url: 'https://m.example/',
        urlTemplate: 'https://m.example/read/{original}?fallback={url}',
      );

      expect(
        mirror.buildUrl(_article),
        'https://m.example/read/'
        'https%3A%2F%2Fmedium.com%2F%40user%2Fa-post%3Fx%3D1'
        '?fallback=$_article',
      );
    });
  });

  group('MirrorSource.allowedHosts', () {
    test('contains the mirror host and every redirect alias', () {
      final mirror = MirrorSource(
        id: 'm',
        name: 'M',
        url: 'https://archive.ph/',
        urlTemplate: 'https://archive.ph/newest/{url}',
        aliases: const ['archive.today', 'Archive.is'],
      );

      expect(
        mirror.allowedHosts,
        {'archive.ph', 'archive.today', 'archive.is'},
      );
    });

    test('is just the host when there are no aliases', () {
      final mirror = MirrorSource(
        id: 'm',
        name: 'M',
        url: 'https://m.example/',
        urlTemplate: 'https://m.example/{original}',
      );

      expect(mirror.allowedHosts, {'m.example'});
    });
  });

  group('health tracking', () {
    test('fails over only after the threshold is reached', () {
      final mirror = MirrorSource(
        id: 'm',
        name: 'M',
        url: 'https://m.example/',
        urlTemplate: 'https://m.example/{original}',
      );

      for (var i = 1; i < MirrorSource.failureThreshold; i++) {
        mirror.recordFailure();
        expect(mirror.available, isTrue);
      }

      mirror.recordFailure();
      expect(mirror.available, isFalse);
      expect(mirror.consecutiveFailures, MirrorSource.failureThreshold);
    });

    test('a success clears both the count and the outage', () {
      final mirror = MirrorSource(
        id: 'm',
        name: 'M',
        url: 'https://m.example/',
        urlTemplate: 'https://m.example/{original}',
      );

      for (var i = 0; i < MirrorSource.failureThreshold; i++) {
        mirror.recordFailure();
      }
      mirror.recordSuccess();

      expect(mirror.available, isTrue);
      expect(mirror.consecutiveFailures, 0);
    });

    test('resetHealth puts a mirror back in rotation', () {
      final mirror = MirrorSource(
        id: 'm',
        name: 'M',
        url: 'https://m.example/',
        urlTemplate: 'https://m.example/{original}',
      );

      for (var i = 0; i < MirrorSource.failureThreshold; i++) {
        mirror.recordFailure();
      }
      mirror.resetHealth();

      expect(mirror.available, isTrue);
      expect(mirror.consecutiveFailures, 0);
    });
  });

  group('MirrorCatalog', () {
    test('starts with the verified Freedium mirror', () {
      final first = MirrorCatalog.createDefaults().first;
      expect(first.id, 'freedium');
      expect(first.url, startsWith('https://freedium-mirror.cfd/'));
    });

    test('includes every known backend', () {
      final ids = MirrorCatalog.createDefaults().map((m) => m.id).toList();

      expect(
        ids,
        containsAll([
          'freedium',
          'mirror',
          'freedium-legacy',
          'archive-ph',
          'archive-is',
        ]),
      );
    });

    test('the web mirror uses the query-parameter route it serves', () {
      final mirror = MirrorCatalog.createDefaults().firstWhere(
        (m) => m.id == 'mirror',
      );

      expect(mirror.urlTemplate, contains('/read?url={original}'));
      expect(mirror.buildUrl(_article), startsWith('${mirror.url}read?url='));
    });

    test('archive mirrors use the prefix form and cover redirect hosts', () {
      final archive = MirrorCatalog.createDefaults().firstWhere(
        (m) => m.id == 'archive-ph',
      );

      expect(archive.urlTemplate, endsWith('/newest/{url}'));
      expect(archive.buildUrl(_article), endsWith('/newest/$_article'));
      expect(archive.allowedHosts, contains('archive.today'));
      expect(archive.allowedHosts, contains('archive.is'));
    });

    test('returns a fresh list on every call', () {
      final first = MirrorCatalog.createDefaults().first;
      for (var i = 0; i < MirrorSource.failureThreshold; i++) {
        first.recordFailure();
      }

      expect(MirrorCatalog.createDefaults().first.available, isTrue);
    });
  });
}
