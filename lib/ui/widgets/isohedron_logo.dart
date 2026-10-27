import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class IsohedronLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final TextStyle? textStyle;
  final bool animate;

  const IsohedronLogo({
    super.key,
    this.size = 36.0,
    this.showText = false,
    this.textStyle,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    final emblem = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IsohedronPainter(),
      ),
    );

    if (!showText) return emblem;

    final theme = Theme.of(context);
    final effectiveStyle = textStyle ??
        theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: theme.colorScheme.onSurface,
        ) ??
        const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        emblem,
        SizedBox(width: size * 0.28),
        Text(
          'Isohedron',
          style: effectiveStyle,
        ),
      ],
    );
  }
}

class _IsohedronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) * 0.94;

    // Outer 6 vertices forming regular hexagon
    final outer = List.generate(6, (i) {
      final angle = -math.pi / 2 + i * (math.pi / 3);
      return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
    });

    // Inner 3 vertices forming central equilateral triangle
    final innerR = r * 0.48;
    final inner = List.generate(3, (i) {
      final angle = -math.pi / 2 + i * (2 * math.pi / 3);
      return Offset(cx + innerR * math.cos(angle), cy + innerR * math.sin(angle));
    });

    // Outer points:
    // 0: Top (0, -r)
    // 1: Top-Right
    // 2: Bottom-Right
    // 3: Bottom (0, +r)
    // 4: Bottom-Left
    // 5: Top-Left

    // Inner points:
    // i0: Top-Center
    // i1: Bottom-Right inner
    // i2: Bottom-Left inner

    // Polygons (triangular facets) and their colors
    final facets = <_Facet>[
      // Center facet (Focal jewel with crimson accent touch)
      _Facet(
        [inner[0], inner[1], inner[2]],
        AppTheme.accent, // Crimson #D91A2A
      ),
      // Top facet
      _Facet(
        [outer[0], inner[0], outer[5]],
        const Color(0xFF3B8EE8),
      ),
      // Top-right facet
      _Facet(
        [outer[0], outer[1], inner[0]],
        const Color(0xFF5CA3EE),
      ),
      // Right upper facet
      _Facet(
        [outer[1], inner[1], inner[0]],
        AppTheme.primary, // #1A6FBF
      ),
      // Right lower facet
      _Facet(
        [outer[1], outer[2], inner[1]],
        const Color(0xFF165FA4),
      ),
      // Bottom right facet
      _Facet(
        [outer[2], outer[3], inner[1]],
        const Color(0xFF114B82),
      ),
      // Bottom facet
      _Facet(
        [outer[3], inner[2], inner[1]],
        const Color(0xFF0D3B68),
      ),
      // Bottom left facet
      _Facet(
        [outer[3], outer[4], inner[2]],
        const Color(0xFF135390),
      ),
      // Left lower facet
      _Facet(
        [outer[4], outer[5], inner[2]],
        const Color(0xFF1A6FBF),
      ),
      // Left upper facet
      _Facet(
        [outer[5], inner[0], inner[2]],
        const Color(0xFF2E82DD),
      ),
    ];

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.width * 0.024)
      ..color = const Color(0xFFF5F0E8).withOpacity(0.85) // Linen facet borders
      ..strokeJoin = StrokeJoin.round;

    for (final facet in facets) {
      final path = Path()
        ..moveTo(facet.points[0].dx, facet.points[0].dy)
        ..lineTo(facet.points[1].dx, facet.points[1].dy)
        ..lineTo(facet.points[2].dx, facet.points[2].dy)
        ..close();

      fillPaint.color = facet.color;
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }

    // Outer subtle boundary ring
    final outerPath = Path()..moveTo(outer[0].dx, outer[0].dy);
    for (int i = 1; i < 6; i++) {
      outerPath.lineTo(outer[i].dx, outer[i].dy);
    }
    outerPath.close();

    final outerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, size.width * 0.035)
      ..color = const Color(0xFF104477).withOpacity(0.5)
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(outerPath, outerStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Facet {
  final List<Offset> points;
  final Color color;

  _Facet(this.points, this.color);
}
