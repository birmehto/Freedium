import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/routes/app_routes.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/features/article/models/article_meta.dart';
import 'package:freedium/features/favorites/controllers/favorites_controller.dart';
import 'package:freedium/features/favorites/models/favorite_article.dart';
import 'package:freedium/features/favorites/views/favorites_page.dart';
import 'package:freedium/features/favorites/widgets/favorite_tile.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as ui;

import '../../helpers/test_env.dart';

FavoriteArticle article(
  String url, {
  String title = 'Title',
  String? author,
  String? domain,
}) => FavoriteArticle(
  title: title,
  url: url,
  visitedAt: DateTime.utc(2026),
  author: author,
  domain: domain,
);

class _ArticleStub extends StatelessWidget {
  const _ArticleStub();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('article stub')));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late FavoritesController controller;

  setUp(() {
    final services = registerServices();
    storage = services.storage;
    controller = FavoritesController(storage);
    Get.put<FavoritesController>(controller);
  });

  Widget buildTestApp() => M3ETheme(
    data: M3EThemeData.light(seedColor: testSeedColor),
    child: GetMaterialApp(
      localizationsDelegates: const [ui.DefaultMaterialLocalizations.delegate],
      initialRoute: AppRoutes.home,
      getPages: [
        GetPage(name: AppRoutes.home, page: () => const FavoritesPage()),
        GetPage(name: AppRoutes.article, page: () => const _ArticleStub()),
      ],
    ),
  );

  group('FavoriteArticle', () {
    test('fromJson parses every field', () {
      final parsed = FavoriteArticle.fromJson({
        'title': 'Test Article',
        'url': 'https://medium.com/test',
        'visitedAt': '2026-05-19T12:00:00.000Z',
        'author': 'Test Author',
        'domain': 'medium.com',
        'imageUrl': 'https://medium.com/image.png',
      });

      expect(parsed.title, 'Test Article');
      expect(parsed.url, 'https://medium.com/test');
      expect(parsed.visitedAt, DateTime.parse('2026-05-19T12:00:00.000Z'));
      expect(parsed.author, 'Test Author');
      expect(parsed.domain, 'medium.com');
      expect(parsed.imageUrl, 'https://medium.com/image.png');
    });

    test('toJson round-trips', () {
      final original = FavoriteArticle(
        title: 'Round Trip',
        url: 'https://medium.com/round',
        visitedAt: DateTime.utc(2026, 1, 15, 10, 30),
        author: 'Author',
        domain: 'medium.com',
        imageUrl: 'https://medium.com/img.png',
      );

      final decoded = FavoriteArticle.fromJson(original.toJson());

      expect(decoded.title, original.title);
      expect(decoded.url, original.url);
      expect(decoded.visitedAt, original.visitedAt);
      expect(decoded.author, original.author);
      expect(decoded.domain, original.domain);
      expect(decoded.imageUrl, original.imageUrl);
    });

    test('fromJson tolerates missing optional fields', () {
      final parsed = FavoriteArticle.fromJson({
        'title': 'Minimal',
        'url': 'https://medium.com/min',
        'visitedAt': DateTime.now().toIso8601String(),
      });

      expect(parsed.author, isNull);
      expect(parsed.domain, isNull);
      expect(parsed.imageUrl, isNull);
    });

    test('copyWith replaces only the provided fields', () {
      final original = article(
        'https://medium.com/original',
        title: 'Original',
        author: 'Author',
        domain: 'medium.com',
      );

      final updated = original.copyWith(title: 'Updated', domain: 'dev.to');

      expect(updated.title, 'Updated');
      expect(updated.domain, 'dev.to');
      expect(updated.url, original.url);
      expect(updated.visitedAt, original.visitedAt);
      expect(updated.author, original.author);
    });
  });

  group('FavoritesController', () {
    test('reads favorites from the store', () async {
      await storage.library.addToFavorites(
        article('https://medium.com/hello', title: 'Hello'),
      );

      expect(controller.favorites, hasLength(1));
      expect(controller.favorites.first.title, 'Hello');
    });

    test('is empty when nothing is saved', () {
      expect(controller.favorites, isEmpty);
    });

    test('removeFavorite updates the store and the list', () async {
      const url = 'https://medium.com/hello';
      await storage.library.addToFavorites(article(url));

      await controller.removeFavorite(url);

      expect(controller.favorites, isEmpty);
      expect(storage.library.favorites, isEmpty);
    });

    test(
      'removeFavorite also drops what was stored about the article',
      () async {
        const url = 'https://medium.com/hello';
        await storage.library.addToFavorites(article(url));
        await storage.library.cacheMeta(
          url,
          const ArticleMeta(title: 'Hello', wordCount: 400),
        );
        await storage.cache.save(url: url, html: '<article>hello</article>');

        await controller.removeFavorite(url);

        expect(controller.favorites, isEmpty);
        expect(storage.library.metaFor(url), isNull);
        expect(await storage.cache.contains(url), isFalse);
      },
    );

    test('two removals of the same article do not race', () async {
      const url = 'https://medium.com/hello';
      await storage.library.addToFavorites(article(url));

      await Future.wait([
        controller.removeFavorite(url),
        controller.removeFavorite(url),
      ]);

      expect(controller.favorites, isEmpty);
    });

    test('a whitespace-only query is not a search', () {
      controller.onSearchChanged('   ');

      expect(controller.trimmedQuery, isEmpty);
    });

    test(
      'removeFavorite leaves the list unchanged for an unknown URL',
      () async {
        await storage.library.addToFavorites(
          article('https://medium.com/keep', title: 'Keep'),
        );

        await controller.removeFavorite('https://medium.com/missing');

        expect(controller.favorites, hasLength(1));
      },
    );

    test('filteredFavorites matches title, author and domain', () async {
      await storage.library.addToFavorites(
        article('https://medium.com/dart', title: 'Dart Tips'),
      );
      await storage.library.addToFavorites(
        article(
          'https://medium.com/deep',
          title: 'Dart Deep Dive',
          author: 'Alice',
        ),
      );
      await storage.library.addToFavorites(
        article('https://dev.to/post', title: 'On Another', domain: 'dev.to'),
      );

      controller.onSearchChanged('dart');
      expect(controller.filteredFavorites, hasLength(2));

      controller.onSearchChanged('alice');
      expect(controller.filteredFavorites.single.author, 'Alice');

      controller.onSearchChanged('dev.to');
      expect(controller.filteredFavorites.single.domain, 'dev.to');
    });

    test('an empty query returns everything', () async {
      await storage.library.addToFavorites(article('https://medium.com/a'));
      await storage.library.addToFavorites(article('https://medium.com/b'));

      controller.onSearchChanged('   ');

      expect(controller.filteredFavorites, hasLength(2));
    });
  });

  group('FavoritesPage', () {
    testWidgets('renders the empty state', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Your library is empty'), findsOneWidget);
      expect(find.text('Save articles to read them later'), findsOneWidget);
      expect(find.byType(FavoriteTile), findsNothing);
    });

    testWidgets('renders a tile per favorite', (tester) async {
      await storage.library.addToFavorites(
        article('https://medium.com/first', title: 'First Post', author: 'A1'),
      );
      await storage.library.addToFavorites(
        article(
          'https://medium.com/second',
          title: 'Second Post',
          author: 'A2',
        ),
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('First Post'), findsOneWidget);
      expect(find.text('Second Post'), findsOneWidget);
      expect(find.text('Your library is empty'), findsNothing);
      expect(find.byType(FavoriteTile), findsNWidgets(2));
    });

    testWidgets('search filters the visible tiles', (tester) async {
      await storage.library.addToFavorites(
        article('https://medium.com/dart', title: 'Dart Tips', author: 'Alice'),
      );
      await storage.library.addToFavorites(
        article(
          'https://medium.com/flutter',
          title: 'Flutter Guide',
          author: 'Bob',
        ),
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'dart');
      await tester.pumpAndSettle();

      expect(find.text('Dart Tips'), findsOneWidget);
      expect(find.text('Flutter Guide'), findsNothing);

      await tester.enterText(find.byType(EditableText), 'xyz');
      await tester.pumpAndSettle();

      expect(find.textContaining('No results for'), findsOneWidget);
      expect(find.text('Try a different keyword'), findsOneWidget);
      expect(find.byType(FavoriteTile), findsNothing);
    });

    testWidgets('opens the article route when a tile is tapped', (
      tester,
    ) async {
      await storage.library.addToFavorites(
        article('https://medium.com/tap', title: 'Tap Me'),
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(find.text('article stub'), findsOneWidget);
      expect(Get.currentRoute, AppRoutes.article);
    });

    /// Shows the library page and guarantees it is unmounted afterwards.
    ///
    /// Unmounting matters between these tests: a swipe leaves a spring
    /// animation running, and an app left mounted rebuilds on the next test's
    /// frame, after `Get.reset` has already taken its controller away.
    Future<void> mountPage(WidgetTester tester) async {
      Get.put<FavoritesController>(FavoritesController(storage));
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    }

    /// Swipes a tile far enough to reveal its delete button, then taps it.
    ///
    /// The swipe is left to settle frame by frame: a spring animation pumped to
    /// completion by `pumpAndSettle` can keep scheduling frames indefinitely
    /// here, and the button is only laid out once the card has snapped open.
    Future<void> tapDeleteAction(WidgetTester tester, String title) async {
      await tester.drag(find.text(title), const Offset(-600, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byIcon(M3EIcons.delete_rounded));
      await tester.pumpAndSettle();
    }

    testWidgets('asks before removing an article', (tester) async {
      const url = 'https://medium.com/confirm';
      await storage.library.addToFavorites(article(url, title: 'Confirm Me'));

      await mountPage(tester);
      await tapDeleteAction(tester, 'Confirm Me');

      expect(find.text('Remove from library?'), findsOneWidget);
      expect(
        find.text('"Confirm Me" will be removed from your library.'),
        findsOneWidget,
      );
      expect(storage.library.isFavorite(url), isTrue);
    });

    testWidgets('keeping the article leaves it in the library', (tester) async {
      const url = 'https://medium.com/keep-it';
      await storage.library.addToFavorites(article(url, title: 'Keep It'));

      await mountPage(tester);
      await tapDeleteAction(tester, 'Keep It');
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();

      expect(find.text('Remove from library?'), findsNothing);
      expect(storage.library.isFavorite(url), isTrue);
      expect(find.text('Keep It'), findsOneWidget);
    });

    testWidgets('confirming removes the article from the library', (
      tester,
    ) async {
      const url = 'https://medium.com/remove-it';
      await storage.library.addToFavorites(article(url, title: 'Remove It'));

      await mountPage(tester);
      await tapDeleteAction(tester, 'Remove It');
      await tester.tap(find.text('Remove'));
      // Bounded pumping rather than `pumpAndSettle`: the dialog is gone but the
      // swipe animation underneath has already been told the row is leaving.
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Remove from library?'), findsNothing);
      expect(find.text('Remove It'), findsNothing);
      expect(controller.favorites, isEmpty);
    });

    testWidgets('dismissing the dialog by tapping outside keeps the article', (
      tester,
    ) async {
      const url = 'https://medium.com/barrier';
      await storage.library.addToFavorites(article(url, title: 'Behind Glass'));

      await mountPage(tester);
      await tapDeleteAction(tester, 'Behind Glass');
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(storage.library.isFavorite(url), isTrue);
      expect(find.text('Behind Glass'), findsOneWidget);
    });

    testWidgets('the list scrolls instead of overflowing', (tester) async {
      for (var i = 0; i < 12; i++) {
        await storage.library.addToFavorites(
          article('https://medium.com/post-$i', title: 'Post $i'),
        );
      }

      await mountPage(tester);

      // Twelve tiles do not fit, so the newest is on screen and the oldest is
      // only reachable by scrolling — a fixed column would have overflowed
      // instead and made the rest of the library unreachable.
      expect(tester.takeException(), isNull);
      expect(find.text('Post 11'), findsOneWidget);
      expect(find.text('Post 0'), findsNothing);

      await tester.drag(
        find.text('Post 11'),
        const Offset(0, -800),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('Post 0'), findsOneWidget);
    });

    testWidgets('lays out without errors', (tester) async {
      await storage.library.addToFavorites(
        article('https://medium.com/layout', title: 'Layout Check'),
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
