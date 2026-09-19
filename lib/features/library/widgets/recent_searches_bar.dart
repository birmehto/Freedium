import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../controllers/library_controller.dart';

/// Horizontal list of recent library searches with a clear action.
class RecentSearchesBar extends StatelessWidget {
  const RecentSearchesBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<LibraryController>();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const Icon(M3EIcons.history_rounded, size: 18),
          const SizedBox(width: 8),
          ...controller.recentSearches.map((query) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(M3EIcons.search_rounded, size: 16),
                label: Text(query),
                onPressed: () => controller.onRecentSearchTap(query),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton(
              onPressed: controller.clearRecentSearches,
              child: Text('Clear', style: theme.textTheme.labelMedium),
            ),
          ),
        ],
      ),
    );
  }
}
