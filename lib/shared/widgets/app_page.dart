import 'package:material_ui/material_ui.dart';

import 'background_painter.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    required this.title,
    required this.slivers,
    super.key,
    this.actions,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.useMeshBackground = true,
  });

  final String title;
  final List<Widget> slivers;
  final List<Widget>? actions;
  final EdgeInsets padding;
  final bool useMeshBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body = CustomScrollView(
      slivers: [
        SliverAppBar.medium(
          title: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          actions: actions,
        ),
        SliverPadding(
          padding: padding,
          sliver: SliverList(delegate: SliverChildListDelegate(slivers)),
        ),
      ],
    );

    if (useMeshBackground) {
      body = MeshGradientBackground(child: body);
    }

    return Scaffold(backgroundColor: theme.colorScheme.surface, body: body);
  }
}
