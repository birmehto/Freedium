import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/features/article/controllers/article_controller.dart';
import 'package:freedium/features/article/models/article_request.dart';
import 'package:freedium/features/article/views/article_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_env.dart';

const _url = 'https://medium.com/@user/a-story';

/// A controller frozen in one state. The page under test only builds UI; it
/// never needs a real WebView load.
class _FakeArticleController extends ArticleController {
  _FakeArticleController(this.initial);

  final ArticleState initial;

  @override
  ArticleState build() => initial;

  @override
  Future<void> open(ArticleRequest request) async {}

  @override
  Future<void> requestRefresh() async {}

  @override
  Future<void> openInBrowser() async {}

  @override
  Future<void> shareArticle() async {}

  @override
  Future<void> toggleFavorite() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestServices services;

  setUp(() {
    services = registerServices();
  });

  Widget buildPage(ArticleState state) {
    final container = ProviderContainer(
      parent: services.container,
      overrides: [
        articleControllerProvider.overrideWith(
          () => _FakeArticleController(state),
        ),
      ],
    );
    addTearDown(container.dispose);

    return wrapTestApp(
      container: container,
      child: const ArticlePage(request: ArticleRequest(url: _url)),
    );
  }

  group('ArticlePage', () {
    testWidgets('renders the reader chrome and actions', (tester) async {
      await tester.pumpWidget(
        buildPage(
          const ArticleState(
            originalUrl: _url,
            isLoading: false,
            isInitialLoad: false,
            readingTime: 5,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5 min read'), findsOneWidget);
      // The reader keeps one save control (the heart in the app bar).
      expect(find.text('Save'), findsNothing);
      expect(find.text('Saved'), findsNothing);
      expect(find.text('Style'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Browser'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the editorial error state', (tester) async {
      await tester.pumpWidget(
        buildPage(
          const ArticleState(
            originalUrl: _url,
            errorMessage: 'The mirror is down.',
            isLoading: false,
            isInitialLoad: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Couldn’t load this story'), findsOneWidget);
      expect(find.text('The mirror is down.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Open in browser'), findsOneWidget);
    });

    testWidgets('shows the offline banner for a saved copy', (tester) async {
      await tester.pumpWidget(
        buildPage(
          const ArticleState(
            originalUrl: _url,
            isOffline: true,
            hasOfflineCopy: true,
            isLoading: false,
            isInitialLoad: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline copy'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('switches the save action when the article is saved', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildPage(
          const ArticleState(
            originalUrl: _url,
            isFavorite: true,
            isLoading: false,
            isInitialLoad: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved'), findsNothing);
      expect(find.byTooltip('Remove from library'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('hides the reading time until it is known', (tester) async {
      await tester.pumpWidget(
        buildPage(
          const ArticleState(
            originalUrl: _url,
            isLoading: false,
            isInitialLoad: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('min read'), findsNothing);
    });
  });
}
