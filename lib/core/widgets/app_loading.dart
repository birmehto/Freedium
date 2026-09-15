import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../extensions/context_ext.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({this.size = 40, this.color, this.strokeWidth, super.key});

  final double size;
  final Color? color;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: M3EProgressIndicator.circularWavy(
          size: size,
          color: color ?? context.colors.primary,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}
