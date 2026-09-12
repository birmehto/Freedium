import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:readora/core/services/storage_service.dart';
import 'package:readora/features/favorites/controllers/favorites_controller.dart';
import 'package:readora/features/favorites/models/favorite_article.dart';

class MockStorageService extends StorageService {
  final List<Map<String, dynamic>> _favorites = [];

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
  });
}
