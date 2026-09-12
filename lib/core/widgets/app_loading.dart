import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../extensions/context_ext.dart';

/// Full-area centered loader used while content is loading.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: M3EProgressIndicator.circular(color: context.colors.primary),
    );
  }
}