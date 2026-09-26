import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/routes/app_routes.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/features/article/models/article_meta.dart';
import 'package:freedium/features/favorites/controllers/favorites_controller.dart';
import 'package:freedium/features/favorites/models/continue_reading_item.dart';
import 'package:freedium/features/favorites/models/favorite_article.dart';
import 'package:freedium/features/favorites/views/favorites_page.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as ui;

import '../../helpers/test_env.dart';

/// Covers the "Continue reading" list above the saved articles.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const unfinished = 'https://medium.com/@someone/unfinished-story';

  late StorageService storage;
  late FavoritesController controller;

  setUp(() {
    storage = registerServices().storage;
  });

  Widget buildTestApp() => M3ETheme(
    data: M3EThemeData.light(seedColor: testSeedColor),
    child: GetMaterialApp(
      localizationsDelegates: const [ui.DefaultMaterialLocalizations.delegate],
      initialRoute: AppRoutes.home,
      getPages: [
        GetPage(name: AppRoutes.home, page: () => const FavoritesPage()),
        GetPage(
          name: AppRoutes.article,
          page: () => const Scaffold(body: Text('article stub')),
        ),
      ],
    ),
  );

  Future<void> saveFavorite(String url) => storage.library.addToFavorites(
    FavoriteArticle(title: 'Saved', url: url, visitedAt: DateTime.utc(2026)),
  );

  /// Shows the library page with whatever the test stored in it.
  ///
  /// The controller is registered once the data is in place and the previous
  /// test's app is gone: a page test cannot leave two [GetMaterialApp]s alive at
  /// once, and the reading-progress query the controller starts on registration
  /// must not be queued behind another database write.
  Future<void> mountPage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    Get.put<FavoritesController>(FavoritesController(storage));
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('offers the articles the reader left unfinished', (tester) async {
    await saveFavorite('https://medium.com/one');
    await storage.library.cacheMeta(
      unfinished,
      const ArticleMeta(
        title: 'Halfway Through',
        author: 'Ada',
        wordCount: 600,
      ),
    );
    await storage.progress.save(unfinished, ratio: 0.4);

    await mountPage(tester);

    // The section header is styled in caps.
    expect(find.text('CONTINUE READING'), findsOneWidget);
    expect(find.text('Halfway Through'), findsOneWidget);
    expect(find.textContaining('Ada'), findsOneWidget);
    expect(find.textContaining('40% read'), findsOneWidget);
  });

  testWidgets('appears when the stored positions arrive after the first frame', (
    tester,
  ) async {
    // In the app the controller is created while the page builds, so the
    // reading-progress query always finishes after the first frame. Reading the
    // list inside the section's own build would leave the page subscribed to
    // nothing, and the section would never appear at all.
    await saveFavorite('https://medium.com/one');

    controller = FavoritesController(storage);
    Get.put<FavoritesController>(controller);
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    expect(find.text('CONTINUE READING'), findsNothing);

    await storage.progress.save(unfinished, ratio: 0.4);
    controller.refreshContinueReading();
    await tester.pumpAndSettle();

    expect(find.text('CONTINUE READING'), findsOneWidget);
    expect(find.text('Untitled article'), findsOneWidget);

    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  });

  testWidgets('shows a stand-in title for an article with no metadata', (
    tester,
  ) async {
    await saveFavorite('https://medium.com/one');
    await storage.progress.save(unfinished, ratio: 0.25);

    await mountPage(tester);

    expect(find.text('Untitled article'), findsOneWidget);
  });

  testWidgets('leaves out articles that were finished', (tester) async {
    await saveFavorite('https://medium.com/one');
    await storage.library.cacheMeta(
      unfinished,
      const ArticleMeta(title: 'Already Read', wordCount: 600),
    );
    await storage.progress.save(unfinished, ratio: 1.0);

    await mountPage(tester);

    expect(find.text('CONTINUE READING'), findsNothing);
    expect(find.text('Already Read'), findsNothing);
  });

  testWidgets('stays out of the way while the library is searched', (
    tester,
  ) async {
    await saveFavorite('https://medium.com/dart');
    await storage.progress.save(unfinished, ratio: 0.4);

    await mountPage(tester);
    expect(find.text('CONTINUE READING'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'dart');
    await tester.pumpAndSettle();

    expect(find.text('CONTINUE READING'), findsNothing);
  });

  testWidgets('opens the article from the section', (tester) async {
    await saveFavorite('https://medium.com/one');
    await storage.progress.save(unfinished, ratio: 0.4);

    await mountPage(tester);

    await tester.tap(find.text('Untitled article'));
    await tester.pumpAndSettle();

    expect(find.text('article stub'), findsOneWidget);
    expect(Get.currentRoute, AppRoutes.article);
  });

  group('ContinueReadingItem', () {
    test('reports the position as a percentage', () {
      expect(
        const ContinueReadingItem(url: 'a', title: 'A', ratio: 0).percent,
        0,
      );
      expect(
        const ContinueReadingItem(url: 'a', title: 'A', ratio: 0.456).percent,
        46,
      );
      expect(
        const ContinueReadingItem(url: 'a', title: 'A', ratio: 1).percent,
        100,
      );
    });

    test('clamps a percentage that is out of range', () {
      expect(
        const ContinueReadingItem(url: 'a', title: 'A', ratio: 1.4).percent,
        100,
      );
      expect(
        const ContinueReadingItem(url: 'a', title: 'A', ratio: -0.4).percent,
        0,
      );
    });

    test('falls back to a stand-in title', () {
      expect(
        const ContinueReadingItem(url: 'a', title: '', ratio: 0.5).displayTitle,
        'Untitled article',
      );
      expect(
        const ContinueReadingItem(
          url: 'a',
          title: 'Real',
          ratio: 0.5,
        ).displayTitle,
        'Real',
      );
    });
  });
}
