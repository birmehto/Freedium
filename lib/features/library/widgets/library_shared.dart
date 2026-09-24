import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/network/article_url.dart';
import '../../../core/routes/app_routes.dart';

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
