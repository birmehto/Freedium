import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/storage/app_database.dart';
import 'package:freedium/core/storage/reading_progress_store.dart';
import 'package:freedium/features/article/models/reading_progress.dart';

/// Covers stored reading positions against a real (in-memory) database.
void main() {
  late AppDatabase database;
  late ReadingProgressStore progress;

  String url(int index) => 'https://medium.com/@someone/story-$index';

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    progress = ReadingProgressStore(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('saving and reading', () {
    test('an unread article has no stored position', () async {
      expect(await progress.progressFor(url(1)), isNull);
    });

    test('round-trips a position', () async {
      await progress.save(url(1), ratio: 0.42, offset: 1200);

      final stored = await progress.progressFor(url(1));
      expect(stored?.url, url(1));
      expect(stored?.ratio, closeTo(0.42, 1e-9));
      expect(stored?.offset, closeTo(1200, 1e-9));
      expect(stored?.isStarted, isTrue);
      expect(stored?.isFinished, isFalse);
    });

    test('a blank URL is ignored', () async {
      await progress.save('   ', ratio: 0.5);

      expect(await progress.continueReading(), isEmpty);
    });

    test('a position outside 0..1 is clamped into it', () async {
      await progress.save(url(1), ratio: 1.8);
      await progress.save(url(2), ratio: -0.4);

      expect((await progress.progressFor(url(1)))?.ratio, 1.0);
      expect((await progress.progressFor(url(2)))?.ratio, 0.0);
    });

    test('reading on keeps the time the article was first opened', () async {
      await progress.save(url(1), ratio: 0.1);
      final first = (await progress.progressFor(url(1)))!;

      await progress.save(url(1), ratio: 0.6);
      final reread = (await progress.progressFor(url(1)))!;

      expect(reread.startedAt, first.startedAt);
      expect(
        reread.updatedAt!.isBefore(first.updatedAt!),
        isFalse,
        reason: 'the article was read later, so it was updated later',
      );
      expect(reread.ratio, closeTo(0.6, 1e-9));
    });

    test('survives a restart', () async {
      await progress.save(url(1), ratio: 0.25, offset: 400);

      final reopened = ReadingProgressStore(database);
      final stored = await reopened.progressFor(url(1));

      expect(stored?.ratio, closeTo(0.25, 1e-9));
      expect(stored?.offset, closeTo(400, 1e-9));
    });
  });

  group('continueReading', () {
    test('is empty when nothing has been read', () async {
      expect(await progress.continueReading(), isEmpty);
    });

    test('lists unfinished articles most recently read first', () async {
      await progress.save(url(1), ratio: 0.3);
      await progress.save(url(2), ratio: 0.4);
      await progress.save(url(3), ratio: 0.5);

      final items = await progress.continueReading();

      expect(items.map((item) => item.url), [url(3), url(2), url(1)]);
    });

    test('leaves out articles that were barely opened', () async {
      await progress.save(url(1), ratio: 0.01);

      expect(await progress.continueReading(), isEmpty);
    });

    test('leaves out articles that were finished', () async {
      await progress.save(url(1), ratio: 0.99);

      expect(await progress.continueReading(), isEmpty);
    });

    test('caps the list', () async {
      for (var i = 0; i < 8; i++) {
        await progress.save(url(i), ratio: 0.2 + i / 20);
      }

      final items = await progress.continueReading();

      expect(items, hasLength(ReadingProgressStore.continueReadingLimit));
      expect(items.first.url, url(7));
    });

    test('honours a smaller limit', () async {
      for (var i = 0; i < 4; i++) {
        await progress.save(url(i), ratio: 0.5);
      }

      expect(await progress.continueReading(limit: 2), hasLength(2));
    });

    test(
      'the newest finished articles do not hide the unfinished ones',
      () async {
        await progress.save(url(1), ratio: 0.3);
        await progress.save(url(2), ratio: 1.0);
        await progress.save(url(3), ratio: 1.0);
        await progress.save(url(4), ratio: 1.0);
        await progress.save(url(5), ratio: 1.0);
        await progress.save(url(6), ratio: 1.0);
        await progress.save(url(7), ratio: 1.0);

        final items = await progress.continueReading();

        expect(items.map((item) => item.url), [url(1)]);
      },
    );
  });

  group('forgetting', () {
    test('remove drops one article', () async {
      await progress.save(url(1), ratio: 0.5);
      await progress.save(url(2), ratio: 0.5);

      await progress.remove(url(1));

      expect(await progress.progressFor(url(1)), isNull);
      expect(await progress.progressFor(url(2)), isNotNull);
    });

    test('removing an unknown article changes nothing', () async {
      await progress.save(url(1), ratio: 0.5);

      await progress.remove('https://medium.com/missing');

      expect(await progress.progressFor(url(1)), isNotNull);
    });

    test('clearFinished drops finished articles and keeps the rest', () async {
      await progress.save(url(1), ratio: 0.4);
      await progress.save(url(2), ratio: 0.99);

      await progress.clearFinished();

      expect(await progress.progressFor(url(1)), isNotNull);
      expect(await progress.progressFor(url(2)), isNull);
    });
  });

  group('regressions', () {
    test('newer finished articles do not hide the unfinished ones', () async {
      // The unfinished article is written first, then a reader finishes a
      // couple of dozen others after it. Filtering after a bounded read used to
      // let those finished rows push it out of the window and leave the library
      // looking empty.
      await progress.save(url(1), ratio: 0.5);

      for (var i = 2; i < 30; i++) {
        await progress.save(url(i), ratio: 0.99);
      }

      final resumable = await progress.continueReading();

      expect(resumable.map((entry) => entry.url), contains(url(1)));
      expect(resumable.length, 1);
    });

    test('the newest unfinished articles are the ones returned', () async {
      for (var i = 1; i <= 8; i++) {
        await progress.save(url(i), ratio: 0.5);
      }

      final resumable = await progress.continueReading(limit: 3);

      expect(resumable.map((entry) => entry.url), [url(8), url(7), url(6)]);
    });
  });

  group('ReadingProgress', () {
    test('classifies positions', () {
      expect(const ReadingProgress(url: 'a').isResumable, isFalse);
      expect(const ReadingProgress(url: 'a', ratio: 0.5).isResumable, isTrue);
      expect(const ReadingProgress(url: 'a', ratio: 0.99).isResumable, isFalse);
    });

    test('a first-second read counts as started', () {
      expect(const ReadingProgress(url: 'a', ratio: 0.25).isStarted, isTrue);
      expect(const ReadingProgress(url: 'a').isStarted, isFalse);
    });

    test('a finished article can be read again', () {
      expect(const ReadingProgress(url: 'a', ratio: 1.0).isFinished, isTrue);
      expect(const ReadingProgress(url: 'a', ratio: 0.9).isFinished, isFalse);
    });
  });
}
