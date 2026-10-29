import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Decorative contour-line pattern: iso-lines of a smooth synthetic height
/// field, traced with marching squares so lines never cross. Deterministic
/// (fixed seed) so it is stable across rebuilds. Ornament, not map data.
class TopoBackground extends StatelessWidget {
  const TopoBackground({super.key, this.color = AppColors.topoLine});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: _TopoPainter(color), size: Size.infinite),
    );
  }
}

class _Hill {
  const _Hill(this.center, this.radius, this.height);
  final Offset center;
  final double radius;
  final double height;
}

class _TopoPainter extends CustomPainter {
  _TopoPainter(this.color);
  final Color color;

  static const _cell = 6.0;
  static const _levels = 26;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rnd = math.Random(11);
    final hills = List.generate(
      6,
      (_) => _Hill(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        size.shortestSide * (0.25 + rnd.nextDouble() * 0.45),
        (rnd.nextBool() ? 1 : -0.6) * (0.6 + rnd.nextDouble() * 0.6),
      ),
    );

    double height(double x, double y) {
      var h =
          0.12 * math.sin(x * 0.011 + y * 0.004) +
          0.08 * math.sin(y * 0.017 - x * 0.006);
      for (final hill in hills) {
        final d2 =
            (x - hill.center.dx) * (x - hill.center.dx) +
            (y - hill.center.dy) * (y - hill.center.dy);
        h += hill.height * math.exp(-d2 / (hill.radius * hill.radius));
      }
      return h;
    }

    final cols = (size.width / _cell).ceil() + 1;
    final rows = (size.height / _cell).ceil() + 1;
    final field = List.generate(
      rows,
      (r) => List.generate(cols, (c) => height(c * _cell, r * _cell)),
    );

    var lo = double.infinity, hi = -double.infinity;
    for (final row in field) {
      for (final v in row) {
        lo = math.min(lo, v);
        hi = math.max(hi, v);
      }
    }

    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    final index = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = color;

    for (var l = 1; l < _levels; l++) {
      final level = lo + (hi - lo) * l / _levels;
      final path = Path();
      for (var r = 0; r < rows - 1; r++) {
        for (var c = 0; c < cols - 1; c++) {
          _cellSegments(field, r, c, level, path);
        }
      }
      // Every fifth line is an index contour, as on printed topo maps.
      canvas.drawPath(path, l % 5 == 0 ? index : thin);
    }
  }

  /// Marching squares for one grid cell; appends 0–2 segments to [path].
  static void _cellSegments(
    List<List<double>> f,
    int r,
    int c,
    double level,
    Path path,
  ) {
    final tl = f[r][c], tr = f[r][c + 1];
    final br = f[r + 1][c + 1], bl = f[r + 1][c];
    final mask =
        (tl > level ? 8 : 0) |
        (tr > level ? 4 : 0) |
        (br > level ? 2 : 0) |
        (bl > level ? 1 : 0);
    if (mask == 0 || mask == 15) return;

    final x = c * _cell, y = r * _cell;
    double t(double a, double b) => (level - a) / (b - a);
    final top = Offset(x + _cell * t(tl, tr), y);
    final right = Offset(x + _cell, y + _cell * t(tr, br));
    final bottom = Offset(x + _cell * t(bl, br), y + _cell);
    final left = Offset(x, y + _cell * t(tl, bl));

    void seg(Offset a, Offset b) => path
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy);

    switch (mask) {
      case 1 || 14:
        seg(left, bottom);
      case 2 || 13:
        seg(bottom, right);
      case 3 || 12:
        seg(left, right);
      case 4 || 11:
        seg(top, right);
      case 5:
        seg(left, top);
        seg(bottom, right);
      case 6 || 9:
        seg(top, bottom);
      case 7 || 8:
        seg(left, top);
      case 10:
        seg(left, bottom);
        seg(top, right);
    }
  }

  @override
  bool shouldRepaint(_TopoPainter old) => old.color != color;
}
