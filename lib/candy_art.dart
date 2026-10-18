import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game_engine.dart';

/// Existing palette and APIs are intentionally retained for game compatibility.
const candyPalette = <Color>[
  Color(0xFF20BCFF),
  Color(0xFFFF477C),
  Color(0xFF68D94D),
  Color(0xFFFFD342),
  Color(0xFFFF9635),
  Color(0xFFA96CFF),
];

/// Drop-in replacement for the original CandyPiece widget.
class CandyPiece extends StatelessWidget {
  const CandyPiece({
    super.key,
    required this.type,
    required this.size,
    this.special = SpecialKind.none,
  });

  final int type;
  final double size;
  final SpecialKind special;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: CandyPainter(type, special),
      );
}

/// High-contrast glass candy with soft internal lighting and faceted highlights.
/// Rendering stays static so the existing falling animation is not disturbed.
class CandyPainter extends CustomPainter {
  CandyPainter(this.type, this.special);

  final int type;
  final SpecialKind special;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final base = candyPalette[type % candyPalette.length];
    final deep = Color.lerp(base, const Color(0xFF270C48), .39)!;
    final light = Color.lerp(base, Colors.white, .65)!;

    canvas.drawOval(
      const Rect.fromLTWH(17, 78, 69, 13),
      Paint()
        ..color = const Color(0x80321553)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    if (special == SpecialKind.colorBomb) {
      _drawColorBomb(canvas);
      canvas.restore();
      return;
    }

    Paint glass(Rect bounds) => Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.55, -.65),
        radius: 1.14,
        colors: [Colors.white, light, base, deep],
        stops: const [0, .16, .65, 1],
      ).createShader(bounds);

    final outline = Paint()
      ..color = deep.withValues(alpha: .83)
      ..strokeWidth = 2.15
      ..style = PaintingStyle.stroke;

    switch (type % candyPalette.length) {
      case 0:
        final rect = Rect.fromCircle(center: const Offset(50, 47), radius: 37);
        canvas.drawOval(rect, glass(rect));
        canvas.drawOval(rect, outline);
        canvas.drawOval(const Rect.fromLTWH(25, 17, 38, 15),
            Paint()..color = const Color(0xABFFFFFF));
        canvas.drawArc(const Rect.fromLTWH(19, 15, 64, 66),
            .28, 1.24, false,
            Paint()
              ..color = const Color(0xAAFFFFFF)
              ..strokeWidth = 3
              ..style = PaintingStyle.stroke);
        break;
      case 1:
        canvas.save();
        canvas.translate(50, 48);
        canvas.rotate(-.46);
        final rect = Rect.fromCenter(center: Offset.zero, width: 75, height: 61);
        final shape = RRect.fromRectAndRadius(rect, const Radius.circular(27));
        canvas.drawRRect(shape, glass(rect));
        canvas.drawRRect(shape, outline);
        canvas.drawOval(const Rect.fromLTWH(-25, -23, 40, 13),
            Paint()..color = const Color(0xB6FFFFFF));
        canvas.restore();
        break;
      case 2:
        canvas.save();
        canvas.translate(50, 48);
        canvas.rotate(math.pi / 13);
        final rect = Rect.fromCenter(center: Offset.zero, width: 71, height: 71);
        final shape = RRect.fromRectAndRadius(rect, const Radius.circular(18));
        canvas.drawRRect(shape, glass(rect));
        canvas.drawRRect(shape, outline);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-27, -27, 48, 17),
              const Radius.circular(9)),
          Paint()..color = const Color(0xAAFFFFFF),
        );
        canvas.restore();
        break;
      case 3:
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final a = -math.pi / 2 + i * math.pi / 5;
          final radius = i.isEven ? 39.0 : 22.0;
          final x = 50 + math.cos(a) * radius;
          final y = 49 + math.sin(a) * radius;
          if (i == 0) {
            star.moveTo(x, y);
          } else {
            star.lineTo(x, y);
          }
        }
        star.close();
        final rect = const Rect.fromLTWH(11, 9, 78, 78);
        canvas.drawPath(star, glass(rect));
        canvas.drawPath(star, outline);
        canvas.drawOval(const Rect.fromLTWH(31, 25, 32, 13),
            Paint()..color = const Color(0xB7FFFFFF));
        break;
      case 4:
        canvas.save();
        canvas.translate(50, 48);
        canvas.rotate(.33);
        final rect = Rect.fromCenter(center: Offset.zero, width: 72, height: 70);
        final shape = RRect.fromRectAndRadius(rect, const Radius.circular(30));
        canvas.drawRRect(shape, glass(rect));
        canvas.drawRRect(shape, outline);
        canvas.clipRRect(shape);
        for (final x in [-22.0, 8.0, 38.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(x - 13, -45)
              ..lineTo(x + 1, -45)
              ..lineTo(x - 14, 47)
              ..lineTo(x - 28, 47)
              ..close(),
            Paint()..color = const Color(0xE7FFF6D9),
          );
        }
        canvas.drawOval(const Rect.fromLTWH(-25, -28, 34, 12),
            Paint()..color = const Color(0xA8FFFFFF));
        canvas.restore();
        break;
      default:
        const positions = [
          Offset(37, 28), Offset(59, 28), Offset(25, 47), Offset(49, 48),
          Offset(73, 47), Offset(38, 66), Offset(60, 67),
        ];
        for (final pos in positions) {
          final rect = Rect.fromCircle(center: pos, radius: 17);
          canvas.drawCircle(pos, 17, glass(rect));
          canvas.drawCircle(pos, 17,
              Paint()
                ..color = deep.withValues(alpha: .8)
                ..strokeWidth = 1.25
                ..style = PaintingStyle.stroke);
          canvas.drawOval(Rect.fromLTWH(pos.dx - 9, pos.dy - 10, 14, 6),
              Paint()..color = const Color(0xAAFFFFFF));
        }
    }

    if (special == SpecialKind.horizontal ||
        special == SpecialKind.vertical) {
      final horizontal = special == SpecialKind.horizontal;
      final outer = horizontal
          ? const Rect.fromLTWH(13, 38, 74, 21)
          : const Rect.fromLTWH(39, 10, 22, 76);
      final inner = horizontal
          ? const Rect.fromLTWH(15, 44, 70, 9)
          : const Rect.fromLTWH(45, 12, 10, 72);
      canvas.drawRRect(
        RRect.fromRectAndRadius(outer, const Radius.circular(9)),
        Paint()
          ..color = Colors.white.withValues(alpha: .96)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(inner, const Radius.circular(6)),
        Paint()
          ..shader = const LinearGradient(colors: [
            Color(0xFFFFEE78), Color(0xFFFFA13A), Color(0xFFFFEE78)
          ]).createShader(inner),
      );
      canvas.drawCircle(const Offset(50, 49), 8,
          Paint()..color = const Color(0xFFFD59CA));
      canvas.drawCircle(const Offset(48, 46), 3,
          Paint()..color = Colors.white);
    }

    // Translucent glass edging and tiny bright facets.
    final gleam = Paint()
      ..color = const Color(0xEEFFFFFF)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;
    final x = switch (type % candyPalette.length) {
      3 => 73.0,
      5 => 79.0,
      _ => 81.0,
    };
    final y = switch (type % candyPalette.length) {
      3 => 19.0,
      5 => 17.0,
      _ => 17.0,
    };
    canvas.drawLine(Offset(x - 5, y), Offset(x + 5, y), gleam);
    canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), gleam);
    canvas.drawCircle(Offset(x, y), 2.6, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(23, 67), 2.5,
        Paint()..color = const Color(0xCCFFFFFF));
    canvas.restore();
  }

  void _drawColorBomb(Canvas canvas) {
    const center = Offset(50, 46);
    final bounds = Rect.fromCircle(center: center, radius: 38);
    canvas.drawCircle(center, 42,
        Paint()
          ..color = const Color(0xC8CA67FF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
    canvas.drawCircle(center, 38,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.43, -.58),
            radius: 1.2,
            colors: [Color(0xFFB69CCA), Color(0xFF4A265D),
              Color(0xFF25122C), Color(0xFF0C0615)],
          ).createShader(bounds));
    canvas.drawCircle(center, 38,
        Paint()
          ..color = const Color(0xFFE5B9FF)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke);
    for (var i = 0; i < 29; i++) {
      final angle = i * 2.399963;
      final radius = math.sqrt((i + .5) / 29) * 30;
      final at = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      final r = i.isEven ? 4.2 : 3.4;
      canvas.drawCircle(at, r,
          Paint()..color = candyPalette[i % candyPalette.length]);
      canvas.drawCircle(at.translate(-1.1, -1.2), 1.25,
          Paint()..color = Colors.white);
    }
    canvas.drawOval(const Rect.fromLTWH(27, 14, 32, 11),
        Paint()..color = const Color(0xADFFFFFF));
    canvas.drawCircle(const Offset(79, 13), 3.6,
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CandyPainter old) =>
      old.type != type || old.special != special;
}

/// Layered, painted candy-land scenery; no image assets or network required.
class SceneryPainter extends CustomPainter {
  const SceneryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF80E6FF), Color(0xFFFFD6EE), Color(0xFFFF97CA)],
            stops: [0, .57, 1],
          ).createShader(bounds));

    final sun = Offset(size.width * .80, size.height * .17);
    canvas.drawCircle(sun, size.width * .22,
        Paint()
          ..color = const Color(0xB9FFF2B9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35));
    canvas.drawCircle(sun, size.width * .13,
        Paint()..color = const Color(0xFFFFF6D0));
    canvas.drawCircle(sun, size.width * .135,
        Paint()
          ..color = const Color(0xAAFFFFFF)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);

    void cloud(double x, double y, double scale) {
      final paint = Paint()..color = const Color(0xD9FFFFFF);
      for (final at in <Offset>[
        const Offset(-37, 3), const Offset(-13, -12),
        const Offset(17, -7), const Offset(44, 8),
      ]) {
        canvas.drawCircle(Offset(x + at.dx * scale, y + at.dy * scale),
            23 * scale, paint);
      }
    }
    cloud(size.width * .17, size.height * .21, 1.07);
    cloud(size.width * .84, size.height * .41, .74);
    cloud(size.width * .38, size.height * .51, .68);

    void hill(double y, Color color, double bend) {
      final path = Path()
        ..moveTo(0, size.height)
        ..lineTo(0, y)
        ..cubicTo(size.width * .18, y - bend, size.width * .31, y + bend,
            size.width * .53, y)
        ..cubicTo(size.width * .74, y - bend, size.width * .94, y - bend * .6,
            size.width, y + 8)
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }
    hill(size.height * .78, const Color(0xFFC4F6AF), 67);
    hill(size.height * .86, const Color(0xFF86DFA1), 51);
    hill(size.height * .94, const Color(0xFF55C89E), 39);

    // Fixed floating sugar specks: colorful but inexpensive during gameplay.
    for (var i = 0; i < 18; i++) {
      final x = ((i * 43 + 31) % 101) / 101 * size.width;
      final y = ((i * 67 + 13) % 97) / 97 * size.height;
      final radius = 3.0 + (i % 3) * 2.1;
      final at = Offset(x, y);
      canvas.drawCircle(at, radius * 2,
          Paint()..color = const Color(0x38FFFFFF));
      canvas.drawCircle(at, radius * .57,
          Paint()..color = const Color(0xBFFFFFFF));
    }
  }

  @override
  bool shouldRepaint(covariant SceneryPainter old) => false;
}

/// V3 effect: screen flash, dual shockwaves, radial glow, glossy fragments,
/// colored comet tails, little diamond stars and a soft secondary halo.
/// Uses the SAME constructor as V2; main.dart and game logic do not change.
class SparklePainter extends CustomPainter {
  SparklePainter({
    required this.progress,
    required this.centers,
    required this.colors,
  });

  final double progress;
  final List<Offset> centers;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0).toDouble();
    if (centers.isEmpty || p >= 1 || size.isEmpty) return;
    final fade = math.pow(1 - p, 1.35).toDouble();
    final burst = Curves.easeOutCubic.transform(p);
    final intensity = centers.length >= 7 ? 1.15 : 1.0;
    final flash = (1 - p * 7).clamp(0.0, 1.0).toDouble();
    if (flash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: .18 * flash),
      );
    }

    // Cap the particle count for stable frame-rate in large cascades.
    final count = math.min(14, centers.length);
    for (var j = 0; j < count; j++) {
      final index = j * centers.length ~/ count;
      final center = centers[index];
      final base = colors.isEmpty ? Colors.white : colors[index % colors.length];
      final glowRadius = 24.0 + 22 * burst;
      final glow = (1 - p * 1.55).clamp(0.0, 1.0).toDouble();

      if (glow > 0) {
        canvas.drawCircle(
          center,
          glowRadius,
          Paint()
            ..shader = RadialGradient(colors: [
              Colors.white.withValues(alpha: .75 * glow),
              base.withValues(alpha: .46 * glow),
              base.withValues(alpha: 0),
            ], stops: const [0, .3, 1]).createShader(
                Rect.fromCircle(center: center, radius: glowRadius)),
        );
      }

      // Expanding two-tone rings, slightly delayed for a 'double pop'.
      for (var ringIndex = 0; ringIndex < 2; ringIndex++) {
        final q = ((p - ringIndex * .095) / (1 - ringIndex * .095))
            .clamp(0.0, 1.0).toDouble();
        if (p < ringIndex * .095) continue;
        final f = (1 - q) * fade;
        canvas.drawCircle(
          center,
          5 + Curves.easeOutCubic.transform(q) * (41 + 9 * ringIndex) * intensity,
          Paint()
            ..color = (ringIndex == 0 ? Colors.white : base)
                .withValues(alpha: (.95 * f).clamp(0.0, 1.0))
            ..strokeWidth = 4.8 * f + .5
            ..style = PaintingStyle.stroke,
        );
      }

      // 10 outward-flying shards per blast. Angle and speed are deterministic.
      for (var i = 0; i < 10; i++) {
        final angle = (i * math.pi / 5) + j * .67;
        final speed = 30.0 + (i % 4) * 11.0;
        final distance = 7.0 + burst * speed * intensity;
        final dx = math.cos(angle);
        final dy = math.sin(angle);
        final head = Offset(
          center.dx + dx * distance,
          center.dy + dy * distance + p * p * 13,
        );
        final radius = (5.5 * fade).clamp(.15, 5.5).toDouble();
        final color = i % 3 == 0
            ? Colors.white
            : candyPalette[(index + i) % candyPalette.length];
        final tail = Offset(head.dx - dx * (12 * fade + 2),
            head.dy - dy * (12 * fade + 2));

        canvas.drawLine(
          tail, head,
          Paint()
            ..color = color.withValues(alpha: (.8 * fade).clamp(0.0, 1.0))
            ..strokeWidth = (3.8 * fade).clamp(.15, 3.8).toDouble()
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(head, radius,
            Paint()..color = color.withValues(alpha: (.98 * fade).clamp(0.0, 1.0)));
        canvas.drawCircle(head.translate(-radius * .22, -radius * .28),
            radius * .31,
            Paint()..color = Colors.white.withValues(alpha: fade));

        if (i.isEven) {
          final r = radius * 2.2;
          final diamond = Path()
            ..moveTo(head.dx, head.dy - r)
            ..lineTo(head.dx + r * .36, head.dy)
            ..lineTo(head.dx, head.dy + r)
            ..lineTo(head.dx - r * .36, head.dy)
            ..close();
          canvas.drawPath(diamond,
              Paint()..color = Colors.white.withValues(alpha: (.74 * fade).clamp(0.0, 1.0)));
        }
      }

      // Large matches get a restrained central starburst (no busy text overlap).
      if (centers.length >= 5 && p < .49) {
        final f = ((.49 - p) / .49).clamp(0.0, 1.0).toDouble();
        for (var ray = 0; ray < 6; ray++) {
          final a = ray * math.pi / 3 + index * .25;
          final from = Offset(center.dx + math.cos(a) * 7,
              center.dy + math.sin(a) * 7);
          final to = Offset(center.dx + math.cos(a) * (20 + 17 * burst),
              center.dy + math.sin(a) * (20 + 17 * burst));
          canvas.drawLine(from, to,
              Paint()
                ..color = Colors.white.withValues(alpha: .75 * f)
                ..strokeWidth = 2.4 * f
                ..strokeCap = StrokeCap.round);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SparklePainter old) =>
      progress != old.progress ||
      !identical(centers, old.centers) ||
      !identical(colors, old.colors);
}
