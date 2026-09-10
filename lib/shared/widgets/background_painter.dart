import 'dart:math';

import 'package:material_ui/material_ui.dart';

class MeshGradientBackground extends StatelessWidget {
  const MeshGradientBackground({super.key, this.child, this.animate = true});

  final Widget? child;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final colors = isDark
        ? [
            theme.colorScheme.primary.withValues(alpha: 0.18),
            theme.colorScheme.secondary.withValues(alpha: 0.14),
            theme.colorScheme.tertiary.withValues(alpha: 0.10),
          ]
        : [
            theme.colorScheme.primary.withValues(alpha: 0.10),
            theme.colorScheme.secondary.withValues(alpha: 0.07),
            theme.colorScheme.tertiary.withValues(alpha: 0.05),
          ];

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (animate)
            _AnimatedMesh(colors: colors)
          else
            CustomPaint(painter: MeshGradientPainter(colors: colors)),
          ?child,
        ],
      ),
    );
  }
}

class _AnimatedMesh extends StatefulWidget {
  const _AnimatedMesh({required this.colors});
  final List<Color> colors;

  @override
  State<_AnimatedMesh> createState() => _AnimatedMeshState();
}

class _AnimatedMeshState extends State<_AnimatedMesh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return CustomPaint(
          painter: MeshGradientPainter(colors: widget.colors, t: _ctrl.value),
        );
      },
    );
  }
}

class MeshGradientPainter extends CustomPainter {
  MeshGradientPainter({required this.colors, this.t = 0});

  final List<Color> colors;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 140)
      ..blendMode = BlendMode.plus;

    final blobs = [
      _blob(size, 0.2, 0.3, 0.45, colors[0], 0),
      _blob(size, 0.8, 0.2, 0.55, colors[1], 1),
      _blob(size, 0.3, 0.8, 0.60, colors[2], 2),
      _blob(size, 0.7, 0.7, 0.50, colors[0], 3),
    ];

    for (final b in blobs) {
      paint.color = b.color;
      canvas.drawCircle(b.center, b.radius, paint);
    }
  }

  _Blob _blob(Size size, double x, double y, double r, Color color, int seed) {
    final wobbleX = sin(t * 2 + seed) * 0.05;
    final wobbleY = cos(t * 2 + seed) * 0.05;

    return _Blob(
      center: Offset(size.width * (x + wobbleX), size.height * (y + wobbleY)),
      radius: size.shortestSide * r,
      color: color,
    );
  }

  @override
  bool shouldRepaint(covariant MeshGradientPainter old) {
    return old.t != t || old.colors != colors;
  }
}

class _Blob {
  const _Blob({
    required this.center,
    required this.radius,
    required this.color,
  });

  final Offset center;
  final double radius;
  final Color color;
}
