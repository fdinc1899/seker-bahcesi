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
            colors: [Color(0xFF8DEBFF), Color(0xFFFFD9F1), Color(0xFFFFA0C7)],
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
    hill(size.height * .76, const Color(0xFFD1F7A2), 71);
    hill(size.height * .84, const Color(0xFF9AE7A8), 53);
    hill(size.height * .92, const Color(0xFF67D3B0), 41);

    final river = Path()
      ..moveTo(size.width * .12, size.height)
      ..quadraticBezierTo(size.width * .20, size.height * .88, size.width * .30, size.height * .83)
      ..quadraticBezierTo(size.width * .43, size.height * .77, size.width * .56, size.height * .82)
      ..quadraticBezierTo(size.width * .72, size.height * .89, size.width * .80, size.height)
      ..close();
    canvas.drawPath(river, Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [const Color(0xAAFFFFFF), const Color(0x66AEEAFF), const Color(0x44FFFFFF)],
    ).createShader(Offset.zero & size));

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

/// V4: high-contrast layered effects. The signature is unchanged, so
/// saved games, the engine and its call sites remain compatible.
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
    if (centers.isEmpty || size.isEmpty || p >= 1) return;

    final ease = Curves.easeOutCubic.transform(p);
    final fade = math.pow(1 - p, 1.20).toDouble();
    final initialFlash = (1 - p * 7).clamp(0.0, 1.0).toDouble();
    final centerCount = math.min(12, centers.length);

    // Short, bright board flash: visible even when candies are small.
    if (initialFlash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = const Color(0xFFFFFFFF)
              .withValues(alpha: .25 * initialFlash));
    }

    if (centers.length >= 4) {
      var total = Offset.zero;
      for (final cell in centers) {
        total += cell;
      }
      final middle = total / centers.length.toDouble();
      final halo = (1 - p * 1.2).clamp(0.0, 1.0).toDouble();
      if (halo > 0) {
        final maxRadius = size.shortestSide * .54;
        final radius = 18 + maxRadius * ease;
        canvas.drawCircle(middle, radius, Paint()
          ..color = const Color(0xFFFFD76A)
              .withValues(alpha: .55 * halo)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7 * halo + 1);
        canvas.drawCircle(middle, radius * .91, Paint()
          ..color = Colors.white.withValues(alpha: .48 * halo)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * halo + .5);
      }
    }

    // At most 12 sources and 14 fragments per source. Stable for big cascades.
    for (var j = 0; j < centerCount; j++) {
      final index = j * centers.length ~/ centerCount;
      final center = centers[index];
      final base = colors.isEmpty ? const Color(0xFFFF6EC7)
          : colors[index % colors.length];
      final early = (1 - p * 1.95).clamp(0.0, 1.0).toDouble();
      final glowRadius = 24.0 + 36.0 * ease;

      if (early > 0) {
        canvas.drawCircle(center, glowRadius,
          Paint()..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: .90 * early),
              base.withValues(alpha: .73 * early),
              base.withValues(alpha: 0),
            ],
            stops: const [0, .23, 1],
          ).createShader(Rect.fromCircle(
              center: center, radius: glowRadius)));
      }

      for (var ring = 0; ring < 3; ring++) {
        final delay = ring * .095;
        if (p < delay) continue;
        final q = ((p - delay) / (1 - delay)).clamp(0.0, 1.0).toDouble();
        final ringFade = math.pow(1 - q, 1.1).toDouble();
        final ringRadius = 8 + Curves.easeOutCubic.transform(q) *
            (52 + ring * 13);
        canvas.drawCircle(center, ringRadius, Paint()
          ..color = (ring == 1 ? base :
                  ring == 2 ? const Color(0xFFFFE180) : Colors.white)
              .withValues(alpha: (.91 * ringFade).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.8 * ringFade + .6);
      }

      // Deterministic multi-colour flying shards; no random frame flicker.
      for (var i = 0; i < 14; i++) {
        final angle = i * (math.pi * 2 / 14) + index * .49;
        final dx = math.cos(angle);
        final dy = math.sin(angle);
        final distance = 6 + ease * (36 + (i % 5) * 10);
        final head = Offset(center.dx + dx * distance,
            center.dy + dy * distance + p * p * 20);
        final radius = (6.1 * fade).clamp(.1, 6.1).toDouble();
        final shade = i % 4 == 0 ? Colors.white
            : i % 4 == 1 ? const Color(0xFFFFF2A5)
            : candyPalette[(index + i) % candyPalette.length];
        final tail = head.translate(-dx * (20 * fade + 2),
            -dy * (20 * fade + 2));

        canvas.drawLine(tail, head, Paint()
          ..color = shade.withValues(alpha: .90 * fade)
          ..strokeWidth = 4.5 * fade + .15
          ..strokeCap = StrokeCap.round);
        canvas.drawCircle(head, radius, Paint()
          ..color = shade.withValues(alpha: .95 * fade));
        if (i.isEven) {
          final r = radius * 1.85;
          canvas.drawPath(Path()
            ..moveTo(head.dx, head.dy - r)
            ..lineTo(head.dx + r * .43, head.dy)
            ..lineTo(head.dx, head.dy + r)
            ..lineTo(head.dx - r * .43, head.dy)
            ..close(), Paint()
              ..color = Colors.white.withValues(alpha: .80 * fade));
        }
      }

      final centerFlash = (1 - p * 4).clamp(0.0, 1.0).toDouble();
      if (centerFlash > 0) {
        canvas.drawCircle(center, 10 + 12 * ease,
          Paint()..color = Colors.white.withValues(alpha: .86 * centerFlash));
      }
    }
  }

  @override
  bool shouldRepaint(covariant SparklePainter old) =>
      progress != old.progress ||
      !identical(centers, old.centers) ||
      !identical(colors, old.colors);
}
