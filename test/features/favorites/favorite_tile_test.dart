import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/features/favorites/models/favorite_article.dart';
import 'package:freedium/features/favorites/widgets/favorite_tile.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  FavoriteArticle article({String title = 'A story'}) => FavoriteArticle(
    title: title,
    url: 'https://medium.com/@user/a-story',
    visitedAt: DateTime.utc(2026, 1, 15),
    author: 'Ada Lovelace',
    domain: 'medium.com',
  );

  Widget buildTile({
    required FavoriteArticle item,
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    return wrapTestApp(
      child: Scaffold(
        body: FavoriteTile(
          item: item,
          onTap: onTap ?? () {},
          onDelete: onDelete ?? () {},
        ),
      ),
    );
  }

  group('FavoriteTile', () {
    testWidgets('shows the title and one metadata line', (tester) async {
      await tester.pumpWidget(buildTile(item: article()));
      await tester.pumpAndSettle();

      expect(find.text('A story'), findsOneWidget);
      expect(find.textContaining('Ada Lovelace'), findsOneWidget);
      expect(find.textContaining('medium.com'), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);
    });

    testWidgets('falls back to a title for an untitled article', (
      tester,
    ) async {
      await tester.pumpWidget(buildTile(item: article(title: '   ')));
      await tester.pumpAndSettle();

      expect(find.text('Untitled Article'), findsOneWidget);
    });

    testWidgets('opens the article when tapped', (tester) async {
      var taps = 0;

      await tester.pumpWidget(buildTile(item: article(), onTap: () => taps++));
      await tester.pumpAndSettle();

      await tester.tap(find.text('A story'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('deletes from the trailing control', (tester) async {
      var deletes = 0;

      await tester.pumpWidget(
        buildTile(item: article(), onDelete: () => deletes++),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Remove from library'));
      await tester.pumpAndSettle();

      expect(deletes, 1);
    });
  });
}
