import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/network/article_url.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../article/models/saved_article.dart';
import '../controllers/library_controller.dart';

/// "Today 12:30 PM"-style label used across library lists.
String libraryTimeLabel(DateTime? date) {
  if (date == null) return '';
  return DateFormat.yMMMd().add_jm().format(date);
}

/// Opens a regular article URL.
void openLibraryArticle(String url, {String? title}) {
  final canonical = ArticleUrl.canonicalize(url);
  Get.toNamed(
    AppRoutes.article,
    arguments: {'url': canonical, 'originalUrl': canonical},
  );
}

/// Opens a saved (offline) article.
void openLibrarySavedArticle(SavedArticle saved) {
  Get.toNamed(
    AppRoutes.article,
    arguments: {
      'url': saved.url,
      'originalUrl': saved.url,
      'articleData': {
        'html': saved.html,
        'title': saved.title,
        'author': saved.author,
        'publication': saved.publication,
      },
    },
  );
}

/// Confirmation dialog for clearing the active library section.
Future<void> confirmClearLibrary(BuildContext context) async {
  final controller = Get.find<LibraryController>();
  final action = switch (controller.activeSection.value) {
    LibrarySection.reading || LibrarySection.history => 'history',
    LibrarySection.favorites => 'favorites',
    LibrarySection.saved => 'saved articles',
  };

  M3EDialog.show<void>(
    context,
    dialog: Material(
      child: M3EDialog(
        title: 'Clear $action?',
        content: Text('This will permanently delete all your $action.'),
        actions: [
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(context).pop(),
            label: const Text('Cancel'),
          ),
          AppButton(
            onPressed: () {
              if (controller.activeSection.value == LibrarySection.favorites) {
                controller.clearFavorites();
              } else if (controller.activeSection.value ==
                  LibrarySection.saved) {
                for (final item in controller.saved) {
                  controller.removeSaved(item.url);
                }
              } else {
                controller.clearHistory();
              }
              Navigator.of(context).pop();
            },
            label: const Text('Clear'),
          ),
        ],
      ),
    ),
  );
}
