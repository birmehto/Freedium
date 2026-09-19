import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_empty.dart';
import '../controllers/library_controller.dart';

/// Search-aware empty state for the library sections.
class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LibraryController>();
    final searching = controller.searchQuery.isNotEmpty;

    return AppEmpty(
      icon: searching ? M3EIcons.search_off_rounded : icon,
      title: searching
          ? 'No results for "${controller.searchQuery.value}"'
          : title,
      subtitle: subtitle,
    );
  }
}
