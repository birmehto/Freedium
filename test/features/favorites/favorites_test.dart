import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/routes/app_routes.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/core/services/theme_service.dart';
import 'package:freedium/features/favorites/controllers/favorites_controller.dart';
import 'package:freedium/features/favorites/models/favorite_article.dart';
import 'package:freedium/features/favorites/views/favorites_page.dart';
import 'package:freedium/features/favorites/widgtes/favorite_tile.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as ui;
import 'package:material_ui/material_ui.dart';

class MockStorageService extends StorageService {
  final List<Map<String, dynamic>> _favorites = [];
  bool _isDarkMode = false;

  @override
  bool get isDarkMode => _isDarkMode;

  @override
  set isDarkMode(bool value) {
    _isDarkMode = value;
  }

  @override
  List<dynamic> get favorites => _favorites;

  @override
  Future<void> addToFavorites(Map<String, dynamic> item) async {
    if (!_favorites.any((e) => e['url'] == item['url'])) {
      _favorites.insert(0, item);
    }
  }

  @override
  Future<void> removeFromFavorites(String url) async {
    _favorites.removeWhere((e) => e['url'] == url);
  }

  @override
  bool isFavorite(String url) => _favorites.any((e) => e['url'] == url);
}

class MockThemeService extends ThemeService {
  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = Get.find<StorageService>().isDarkMode;
  }
}

void main() {
  group('FavoriteArticle Tests', () {
    test('fromJson should parse correctly', () {
      final json = {
        'title': 'Test Article',
        'url': 'https://medium.com/test',
        'visitedAt': '2026-05-19T12:00:00.000Z',
        'author': 'Test Author',
        'domain': 'medium.com',
        'imageUrl': 'https://medium.com/image.png',
      };

      final article = FavoriteArticle.fromJson(json);

      expect(article.title, 'Test Article');
      expect(article.url, 'https://medium.com/test');
      expect(article.visitedAt, DateTime.parse('2026-05-19T12:00:00.000Z'));
      expect(article.author, 'Test Author');
      expect(article.domain, 'medium.com');
      expect(article.imageUrl, 'https://medium.com/image.png');
    });

    test('toJson should convert correctly', () {
      final visited = DateTime.parse('2026-05-19T12:00:00.000Z');
      final article = FavoriteArticle(
        title: 'Test Article',
        url: 'https://medium.com/test',
        visitedAt: visited,
        author: 'Test Author',
        domain: 'medium.com',
        imageUrl: 'https://medium.com/image.png',
      );

      final json = article.toJson();

      expect(json['title'], 'Test Article');
      expect(json['url'], 'https://medium.com/test');
      expect(json['visitedAt'], visited.toIso8601String());
      expect(json['author'], 'Test Author');
      expect(json['domain'], 'medium.com');
      expect(json['imageUrl'], 'https://medium.com/image.png');
    });

    test('fromJson round-trip preserves all fields', () {
      final original = FavoriteArticle(
        title: 'Round Trip',
        url: 'https://medium.com/round',
        visitedAt: DateTime.utc(2026, 1, 15, 10, 30),
        author: 'Author',
        domain: 'medium.com',
        imageUrl: 'https://medium.com/img.png',
      );

      final json = original.toJson();
      final decoded = FavoriteArticle.fromJson(json);

      expect(decoded.title, original.title);
      expect(decoded.url, original.url);
      expect(decoded.visitedAt, original.visitedAt);
      expect(decoded.author, original.author);
      expect(decoded.domain, original.domain);
      expect(decoded.imageUrl, original.imageUrl);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'title': 'Minimal',
        'url': 'https://medium.com/min',
        'visitedAt': DateTime.now().toIso8601String(),
      };

      final article = FavoriteArticle.fromJson(json);

      expect(article.author, isNull);
      expect(article.domain, isNull);
      expect(article.imageUrl, isNull);
    });

    test('toJson round-trip preserves all fields', () {
      final json = {
        'title': 'From JSON',
        'url': 'https://medium.com/json',
        'visitedAt': '2026-03-05T14:00:00.000Z',
        'author': 'Writer',
        'domain': 'medium.com',
        'imageUrl': 'https://medium.com/pic.jpg',
      };

      final article = FavoriteArticle.fromJson(json);
      final encoded = article.toJson();
      final decoded = FavoriteArticle.fromJson(encoded);

      expect(decoded.url, article.url);
      expect(decoded.title, article.title);
    });
  });

  group('FavoritesController Tests', () {
    late MockStorageService mockStorage;
    late FavoritesController controller;

    setUp(() {
      Get.reset();
      mockStorage = MockStorageService();
      Get.put<StorageService>(mockStorage);
      controller = FavoritesController(mockStorage);
      controller.onInit();
    });

    test('loadFavorites reads saved favorites from storage', () async {
      mockStorage.addToFavorites(
        FavoriteArticle(
          title: 'Hello',
          url: 'https://medium.com/hello',
          visitedAt: DateTime.now(),
        ).toJson(),
      );

      await controller.loadFavorites();

      expect(controller.favorites.length, 1);
      expect(controller.favorites.first.title, 'Hello');
      expect(controller.favorites.first.url, 'https://medium.com/hello');
    });

    test('loadFavorites returns empty list when storage is empty', () async {
      await controller.loadFavorites();

      expect(controller.favorites, isEmpty);
    });

    test('removeFavorite removes from storage and list', () async {
      const url = 'https://medium.com/hello';
      mockStorage.addToFavorites(
        FavoriteArticle(
          title: 'Hello',
          url: url,
          visitedAt: DateTime.now(),
        ).toJson(),
      );
      await controller.loadFavorites();

      await controller.removeFavorite(url);

      expect(controller.favorites, isEmpty);
      expect(mockStorage.favorites, isEmpty);
    });

    test(
      'removeFavorite leaves list unchanged when url is not found',
      () async {
        mockStorage.addToFavorites(
          FavoriteArticle(
            title: 'Keep',
            url: 'https://medium.com/keep',
            visitedAt: DateTime.now(),
          ).toJson(),
        );
        await controller.loadFavorites();

        await controller.removeFavorite('https://medium.com/missing');

        expect(controller.favorites.length, 1);
        expect(mockStorage.favorites.length, 1);
      },
    );

    test('filteredFavorites matches search query', () async {
      mockStorage.addToFavorites(
        FavoriteArticle(
          title: 'Dart Tips',
          url: 'https://medium.com/dart',
          visitedAt: DateTime.now(),
        ).toJson(),
      );
      mockStorage.addToFavorites(
        FavoriteArticle(
          title: 'Flutter Guide',
          url: 'https://medium.com/flutter',
          visitedAt: DateTime.now(),
        ).toJson(),
      );
      await controller.loadFavorites();

      controller.onSearchChanged('dart');

      expect(controller.filteredFavorites.length, 1);
      expect(controller.filteredFavorites.first.title, 'Dart Tips');
    });

    test('filteredFavorites matches author', () async {
      mockStorage.addToFavorites(
        FavoriteArticle(
          title: 'Dart Deep Dive',
          url: 'https://medium.com/dart-deep',
          visitedAt: DateTime.now(),
          author: 'Alice',
        ).toJson(),
      );
      mockStorage.addToFavorites(
        FavoriteArticle(
          title: 'Flutter Basics',
          url: 'https://medium.com/flutter-basics',
          visitedAt: DateTime.now(),
          author: 'Bob',
        ).toJson(),
      );
      await controller.loadFavorites();

      controller.onSearchChanged('alice');

      expect(controller.filteredFavorites.length, 1);
      expect(controller.filteredFavorites.first.author, 'Alice');
    });

    test('filteredFavorites matches domain', () async {
      mockStorage.addToFavorites(
        FavoriteArticle(
          title: 'On Medium',
          url: 'https://medium.com/on-medium',
          visitedAt: DateTime.now(),
          domain: 'medium.com',
        ).toJson(),
      );
      mockStorage.addToFavorites(
        FavoriteArticle(
          title: 'On Another',
          url: 'https://dev.to/another',
          visitedAt: DateTime.now(),
          domain: 'dev.to',
        ).toJson(),
      );
      await controller.loadFavorites();

      controller.onSearchChanged('dev.to');

      expect(controller.filteredFavorites.length, 1);
      expect(controller.filteredFavorites.first.domain, 'dev.to');
    });
  });

  group('FavoritesPage Widget Tests', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    late MockStorageService mockStorage;

    setUp(() {
      Get.reset();
      mockStorage = MockStorageService();
      Get.put<StorageService>(mockStorage);
      Get.put(MockThemeService());
      Get.put(FavoritesController(mockStorage));
    });

    Widget buildTestApp() {
      return M3ETheme(
        data: M3EThemeData.light(seedColor: const Color(0xFF536DFE)),
        child: GetMaterialApp(
          localizationsDelegates: const [
            ui.DefaultMaterialLocalizations.delegate,
          ],
          initialRoute: AppRoutes.home,
          getPages: [
            GetPage(name: AppRoutes.home, page: () => const FavoritesPage()),
            GetPage(name: AppRoutes.article, page: () => const _ArticleStub()),
          ],
        ),
      );
    }

    testWidgets('renders empty state when there are no favorites', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Your library is empty'), findsOneWidget);
      expect(find.text('Save articles to read them later'), findsOneWidget);
      expect(find.byType(FavoriteTile), findsNothing);
    });

    testWidgets('renders tiles when favorites exist', (tester) async {
      mockStorage.addToFavorites(
        FavoriteArticle(
          title: 'First Post',
          url: 'https://medium.com/first',
          visitedAt: DateTime(2026, 6),
          author: 'Author 1',
          domain: 'medium.com',
        ).toJson(),
      );
      mockStorage.addToFavorites(
        FavoriteArticle(
          title: 'Second Post',
          url: 'https://medium.com/second',
          visitedAt: DateTime(2026, 6, 2),
          author: 'Author 2',
          domain: 'medium.com',
        ).toJson(),
      );
      await Get.find<FavoritesController>().loadFavorites();

      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('First Post'), findsOneWidget);
      expect(find.text('Second Post'), findsOneWidget);
      expect(find.text('Your library is empty'), findsNothing);
      expect(find.byType(FavoriteTile), findsNWidgets(2));
    });

    testWidgets('search filters tiles and updates empty state', (tester) async {
      mockStorage.addToFavorites(
        FavoriteArticle(
          title: 'Dart Tips',
          url: 'https://medium.com/dart',
          visitedAt: DateTime(2026, 6),
          author: 'Alice',
          domain: 'medium.com',
        ).toJson(),
      );
      mockStorage.addToFavorites(
        FavoriteArticle(
          title: 'Flutter Guide',
          url: 'https://medium.com/flutter',
          visitedAt: DateTime(2026, 6, 2),
          author: 'Bob',
          domain: 'medium.com',
        ).toJson(),
      );
      await Get.find<FavoritesController>().loadFavorites();

      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 500));

      // Type into the search field
      await tester.enterText(find.byType(EditableText), 'dart');
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Dart Tips'), findsOneWidget);
      expect(find.text('Flutter Guide'), findsNothing);
      expect(find.byType(FavoriteTile), findsOneWidget);

      // Type a non-matching query
      await tester.enterText(find.byType(EditableText), 'xyz');
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('No results for'), findsOneWidget);
      expect(find.text('Try a different keyword'), findsOneWidget);
      expect(find.byType(FavoriteTile), findsNothing);
    });

    testWidgets('shows no layout errors', (tester) async {
      mockStorage.addToFavorites(
        FavoriteArticle(
          title: 'Layout Check',
          url: 'https://medium.com/layout',
          visitedAt: DateTime(2026, 6),
          author: 'Tester',
          domain: 'medium.com',
        ).toJson(),
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 500));

      final errors = tester.takeException();
      expect(errors, isNull);
    });

    testWidgets('tapping a tile navigates to the article route', (
      tester,
    ) async {
      mockStorage.addToFavorites(
        FavoriteArticle(
          title: 'Tap Me',
          url: 'https://medium.com/tap',
          visitedAt: DateTime(2026, 6),
          author: 'Tester',
          domain: 'medium.com',
        ).toJson(),
      );
      await Get.find<FavoritesController>().loadFavorites();

      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(find.text('article stub'), findsOneWidget);
      expect(Get.currentRoute, AppRoutes.article);
    });
  });
}

class _ArticleStub extends StatelessWidget {
  const _ArticleStub();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('article stub')));
  }
}
