import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../models/hex.dart';
import '../theme.dart';

class HexGridWidget extends StatefulWidget {
  final GameState state;
  final VoidCallback onSubmit;
  const HexGridWidget({super.key, required this.state, required this.onSubmit});

  @override
  State<HexGridWidget> createState() => _HexGridWidgetState();
}

class _HexGridWidgetState extends State<HexGridWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    widget.state.addListener(_onState);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onState);
    _pulse.dispose();
    super.dispose();
  }

  void _onState() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      // Compute hex centers for the puzzle's board (cells = letter positions).
      final cells = widget.state.puzzle.letters.keys.toList();
      // Use unit size = 1, then scale to fit.
      final raw = {for (final c in cells) c: c.toPixel(1.0)};
      final xs = raw.values.map((p) => p.x);
      final ys = raw.values.map((p) => p.y);
      final minX = xs.reduce(min), maxX = xs.reduce(max);
      final minY = ys.reduce(min), maxY = ys.reduce(max);
      final unitW = maxX - minX + sqrt(3); // include hex width
      final unitH = maxY - minY + 2;       // include hex height

      final scale = min(w / unitW, h / unitH);
      final size = scale.clamp(20.0, 80.0); // hex circumradius
      final boardW = unitW * size;
      final boardH = unitH * size;
      final dx = (w - boardW) / 2 - minX * size + sqrt(3) / 2 * size;
      final dy = (h - boardH) / 2 - minY * size + size;

      final centers = <Hex, Offset>{
        for (final c in cells)
          c: Offset(raw[c]!.x * size + dx, raw[c]!.y * size + dy),
      };

      Hex? hitTest(Offset pos) {
        Hex? best;
        double bestDist = size * 0.85; // require touch inside ~hex radius
        centers.forEach((hex, c) {
          final d = (c - pos).distance;
          if (d < bestDist) {
            bestDist = d;
            best = hex;
          }
        });
        return best;
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          final hex = hitTest(d.localPosition);
          if (hex != null) widget.state.beginSelection(hex);
        },
        onPanUpdate: (d) {
          final hex = hitTest(d.localPosition);
          if (hex != null) widget.state.extendSelection(hex);
        },
        onPanEnd: (_) => widget.onSubmit(),
        onTapUp: (d) {
          final hex = hitTest(d.localPosition);
          if (hex != null) {
            // Single-tap toggle: start a single-letter selection then submit.
            widget.state.beginSelection(hex);
          }
        },
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, _) => CustomPaint(
            size: Size(w, h),
            painter: _HexPainter(
              state: widget.state,
              centers: centers,
              hexSize: size,
              pulse: _pulse.value,
            ),
          ),
        ),
      );
    });
  }
}

class _HexPainter extends CustomPainter {
  final GameState state;
  final Map<Hex, Offset> centers;
  final double hexSize;
  final double pulse;

  _HexPainter({
    required this.state,
    required this.centers,
    required this.hexSize,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw connection lines under tiles with a soft glow.
    if (state.selection.length >= 2) {
      final pts = state.selection.map((h) => centers[h]!).toList();
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      // Outer glow.
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.petal.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = hexSize * 0.55
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // Solid gradient line.
      canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            colors: [AppColors.petalDeep, AppColors.petal, Color(0xFFFFD3E6)],
          ).createShader(path.getBounds())
          ..style = PaintingStyle.stroke
          ..strokeWidth = hexSize * 0.28
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      // White inner core for contrast.
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = hexSize * 0.08
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Draw each tile.
    centers.forEach((hex, center) {
      final letter = state.puzzle.letters[hex] ?? '';
      final selected = state.isSelected(hex);
      final bloomed = state.bloomedTiles.contains(hex);
      final hinted = state.isHinted(hex);
      _drawHex(canvas, center, hexSize, selected, bloomed, hinted);
      _drawLetter(canvas, center, letter, hexSize, selected, bloomed);
    });
  }

  void _drawHex(Canvas canvas, Offset c, double size, bool selected, bool bloomed, bool hinted) {
    final path = _hexPath(c, size * 0.92);
    Paint fill;
    Color edge;
    double edgeWidth;
    Color glowColor;
    if (selected) {
      fill = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB6DA), AppColors.tileSelectedTop, AppColors.tileSelectedBottom],
        ).createShader(Rect.fromCircle(center: c, radius: size));
      edge = AppColors.petalDeep;
      edgeWidth = 3.5;
      glowColor = AppColors.petal;
    } else if (bloomed) {
      fill = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.tileBloomTop, AppColors.tileBloomBottom],
        ).createShader(Rect.fromCircle(center: c, radius: size));
      edge = AppColors.tileBloomEdge;
      edgeWidth = 3;
      glowColor = AppColors.leaf;
    } else if (hinted) {
      fill = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.tileHintTop, AppColors.tileHintBottom],
        ).createShader(Rect.fromCircle(center: c, radius: size));
      edge = AppColors.sunDeep;
      edgeWidth = 3;
      glowColor = AppColors.sun;
    } else {
      fill = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.tileTop, AppColors.tileBottom],
        ).createShader(Rect.fromCircle(center: c, radius: size));
      edge = AppColors.tileEdge;
      edgeWidth = 2;
      glowColor = AppColors.tileTop;
    }
    // Outer glow halo (subtle for default, stronger when active).
    canvas.drawPath(
      _hexPath(c, size * 0.96),
      Paint()
        ..color = glowColor.withValues(alpha: selected || bloomed || hinted ? 0.45 : 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, selected ? 10 : 6),
    );
    // Soft drop shadow pushed down for 3D depth.
    canvas.drawPath(
      _hexPath(c.translate(0, size * 0.13), size * 0.92),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(path, fill);
    // Inner glassy highlight (top half).
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(c.dx - size, c.dy - size, size * 2, size * 0.7),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.30), Colors.white.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(c.dx - size, c.dy - size, size * 2, size * 0.7)),
    );
    canvas.restore();
    // Edge stroke.
    canvas.drawPath(
      path,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = edgeWidth,
    );

    if (bloomed) {
      // Sparkle stars around the tile.
      final sparkPaint = Paint()..color = AppColors.sun.withValues(alpha: 0.85);
      for (int i = 0; i < 6; i++) {
        final a = (i / 6) * 2 * pi + pulse * pi;
        final p = c + Offset(cos(a), sin(a)) * size * 0.6;
        canvas.drawCircle(p, size * 0.07, sparkPaint);
      }
      canvas.drawCircle(c, size * 0.18,
          Paint()..color = Colors.white.withValues(alpha: 0.20));
    }

    if (hinted && !selected) {
      // Pulsing golden ring.
      canvas.drawCircle(
        c,
        size * (0.97 + 0.06 * pulse),
        Paint()
          ..color = AppColors.sun.withValues(alpha: 0.55 + 0.35 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
    }
    if (selected) {
      // Pulsing pink ring.
      canvas.drawCircle(
        c,
        size * (0.97 + 0.05 * pulse),
        Paint()
          ..color = AppColors.petal.withValues(alpha: 0.40 + 0.40 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
    }
  }

  Path _hexPath(Offset c, double r) {
    final p = Path();
    for (int i = 0; i < 6; i++) {
      // Pointy-top: angle 30° + 60°*i.
      final a = (pi / 180) * (30 + 60 * i);
      final pt = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    return p;
  }

  void _drawLetter(Canvas canvas, Offset c, String letter, double size,
      bool selected, bool bloomed) {
    final color = (selected || bloomed) ? Colors.white : Colors.white;
    final tp = TextPainter(
      text: TextSpan(
        text: letter.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: size * 0.85,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.45),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _HexPainter old) => true;
}
