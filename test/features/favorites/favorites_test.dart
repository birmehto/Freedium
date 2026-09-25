import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/routes/app_routes.dart';
import 'package:freedium/core/services/storage_service.dart';
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
