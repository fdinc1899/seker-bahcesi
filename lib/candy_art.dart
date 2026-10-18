import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game_engine.dart';

const candyPalette = <Color>[
  Color(0xFF20BCFF), // blue drop
  Color(0xFFFF477C), // strawberry jelly
  Color(0xFF68D94D), // lime candy
  Color(0xFFFFD342), // lemon star
  Color(0xFFFF9635), // striped caramel
  Color(0xFFA96CFF), // berry cluster
];

class CandyPiece extends StatelessWidget {
  const CandyPiece({super.key, required this.type, required this.size,
    this.special = SpecialKind.none});
  final int type;
  final double size;
  final SpecialKind special;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: CandyPainter(type, special),
      );
}

class CandyPainter extends CustomPainter {
  CandyPainter(this.type, this.special);
  final int type;
  final SpecialKind special;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final base = candyPalette[type % candyPalette.length];
    final dark = Color.lerp(base, Colors.black, .30)!;
    final pale = Color.lerp(base, Colors.white, .62)!;
    final shadow = Paint()
      ..color = const Color(0xB033145E)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(const Rect.fromLTWH(15, 76, 75, 15), shadow);

    Paint fill(Rect rect) => Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.52, -.70),
        radius: 1.12,
        colors: [const Color(0xFFFFFFFF), pale, base, dark],
        stops: const [0, .14, .64, 1],
      ).createShader(rect);

    final outline = Paint()
      ..color = dark.withValues(alpha: .66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    if (special == SpecialKind.colorBomb) {
      _drawColorBomb(canvas);
      canvas.restore();
      return;
    }
    switch (type) {
      case 0:
        final rect = Rect.fromCircle(center: const Offset(50, 47), radius: 37);
        canvas.drawOval(rect, fill(rect));
        canvas.drawOval(rect, outline);
        canvas.drawOval(const Rect.fromLTWH(29, 18, 33, 15),
            Paint()..color = Colors.white.withValues(alpha: .52));
        canvas.drawArc(const Rect.fromLTWH(17, 15, 67, 68),
            .4, 1.20, false,
            Paint()..color = const Color(0x77FFFFFF)..strokeWidth = 3
              ..style = PaintingStyle.stroke);
        break;
      case 1:
        canvas.save();
        canvas.translate(50, 48);
        canvas.rotate(-.46);
        final rect = Rect.fromCenter(center: Offset.zero, width: 74, height: 58);
        final rr = RRect.fromRectAndRadius(rect, const Radius.elliptical(28, 27));
        canvas.drawRRect(rr, fill(rect));
        canvas.drawRRect(rr, outline);
        canvas.drawOval(const Rect.fromLTWH(-24, -21, 36, 12),
            Paint()..color = Colors.white.withValues(alpha: .62));
        canvas.restore();
        break;
      case 2:
        canvas.save();
        canvas.translate(50, 48);
        canvas.rotate(math.pi / 13);
        final rect = Rect.fromCenter(center: Offset.zero, width: 70, height: 71);
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(18));
        canvas.drawRRect(rr, fill(rect));
        canvas.drawRRect(rr, outline);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-27, -27, 47, 19), const Radius.circular(9)),
          Paint()..color = const Color(0x88FFFFFF),
        );
        canvas.restore();
        break;
      case 3:
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final angle = -math.pi / 2 + i * math.pi / 5;
          final radius = i.isEven ? 39.0 : 22.0;
          final x = 50 + math.cos(angle) * radius;
          final y = 49 + math.sin(angle) * radius;
          if (i == 0) { star.moveTo(x, y); } else { star.lineTo(x, y); }
        }
        star.close();
        final rect = const Rect.fromLTWH(11, 9, 78, 78);
        canvas.drawPath(star, fill(rect));
        canvas.drawPath(star, outline);
        canvas.drawOval(const Rect.fromLTWH(32, 27, 31, 13),
            Paint()..color = const Color(0x9AFFFFFF));
        break;
      case 4:
        canvas.save();
        canvas.translate(50, 48);
        canvas.rotate(.33);
        final rect = Rect.fromCenter(center: Offset.zero, width: 72, height: 70);
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(31));
        canvas.drawRRect(rr, fill(rect));
        canvas.drawRRect(rr, outline);
        canvas.clipRRect(rr);
        for (final x in [-22.0, 8.0, 38.0]) {
          final stripe = Path()
            ..moveTo(x - 14, -45)
            ..lineTo(x + 1, -45)
            ..lineTo(x - 14, 47)
            ..lineTo(x - 29, 47)
            ..close();
          canvas.drawPath(stripe, Paint()..color = const Color(0xCCFFF8D5));
        }
        canvas.drawOval(const Rect.fromLTWH(-24, -27, 33, 12),
            Paint()..color = const Color(0x8CFFFFFF));
        canvas.restore();
        break;
      default:
        const positions = [
          Offset(37, 28), Offset(59, 28), Offset(25, 47), Offset(49, 48),
          Offset(73, 47), Offset(38, 66), Offset(60, 67),
        ];
        for (final pos in positions) {
          final rect = Rect.fromCircle(center: pos, radius: 17);
          canvas.drawCircle(pos, 17, fill(rect));
          canvas.drawCircle(pos, 17, outline..strokeWidth = 1.2);
          canvas.drawOval(Rect.fromLTWH(pos.dx - 9, pos.dy - 10, 13, 6),
              Paint()..color = const Color(0x8AFFFFFF));
        }
    }
    if (special == SpecialKind.horizontal ||
        special == SpecialKind.vertical) {
      final horizontal = special == SpecialKind.horizontal;
      // A bright lightning band makes power candies recognizable while moving.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          horizontal ? const Rect.fromLTWH(14, 40, 72, 17)
              : const Rect.fromLTWH(41, 11, 18, 74),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xE6FFFFFF),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          horizontal ? const Rect.fromLTWH(16, 45, 68, 8)
              : const Rect.fromLTWH(46, 13, 8, 70),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0xFFFCD055),
      );
      canvas.drawCircle(const Offset(50, 49), 8,
          Paint()..color = const Color(0xFFFC68DC));
    }
    // Tiny facets create a candy-glass shine even at small 8x8 tile sizes.
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: .82)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.1;
    final x = switch (type) { 3 => 73.0, 5 => 79.0, _ => 81.0 };
    final y = switch (type) { 3 => 19.0, 5 => 17.0, _ => 17.0 };
    canvas.drawLine(Offset(x - 5, y), Offset(x + 5, y), shine);
    canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), shine);
    canvas.drawCircle(Offset(x, y), 2.2, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(24, 68), 2.5,
        Paint()..color = const Color(0xAAFFFFFF));
    canvas.restore();
  }

  void _drawColorBomb(Canvas canvas) {
    const center = Offset(50, 45);
    final ball = Rect.fromCircle(center: center, radius: 37);
    canvas.drawCircle(const Offset(52, 83), 30,
      Paint()..color = const Color(0x663F1164)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(center, 37, Paint()
      ..shader = const RadialGradient(center: Alignment(-.4, -.55),
        radius: 1.2, colors: [Color(0xFF795779), Color(0xFF422146),
          Color(0xFF24122E), Color(0xFF08060C)])
        .createShader(ball));
    canvas.drawCircle(center, 37, Paint()
      ..color = const Color(0xFFD89CFF)..style = PaintingStyle.stroke
      ..strokeWidth = 2.4);
    for (var i = 0; i < 27; i++) {
      final angle = i * 2.39996;
      final radial = math.sqrt((i + .5) / 27) * 29;
      final pt = Offset(center.dx + math.cos(angle) * radial,
          center.dy + math.sin(angle) * radial);
      canvas.drawCircle(pt, i.isEven ? 4.3 : 3.5,
        Paint()..color = candyPalette[i % candyPalette.length]);
      canvas.drawCircle(pt.translate(-1.2, -1.3), 1.35,
        Paint()..color = Colors.white.withValues(alpha: .83));
    }
    canvas.drawOval(const Rect.fromLTWH(26, 14, 33, 11),
      Paint()..color = const Color(0x9AFFFFFF));
    canvas.drawCircle(const Offset(78, 16), 4,
      Paint()..color = const Color(0xFFF8F4FF));
  }

  @override
  bool shouldRepaint(covariant CandyPainter old) => old.type != type || old.special != special;
}

class SceneryPainter extends CustomPainter {
  const SceneryPainter();

  @override
  void paint(Canvas c, Size s) {
    final sky = Rect.fromLTWH(0, 0, s.width, s.height);
    c.drawRect(sky, Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF95EBFF), Color(0xFFFFD5ED), Color(0xFFFFA9CB)],
      stops: [0.0, .58, 1.0],
    ).createShader(sky));

    final sun = Offset(s.width * .79, s.height * .18);
    c.drawCircle(sun, s.width * .22,
        Paint()..color = const Color(0x99FFF8BB)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34));
    c.drawCircle(sun, s.width * .13,
        Paint()..color = const Color(0xFFFFF5C7));

    void cloud(double x, double y, double k) {
      final brush = Paint()..color = const Color(0xBBFFFFFF);
      for (final p in [
        Offset(-36, 3), Offset(-13, -12), Offset(17, -7), Offset(44, 8),
      ]) {
        c.drawCircle(Offset(x + p.dx * k, y + p.dy * k), 23 * k, brush);
      }
    }
    cloud(s.width * .17, s.height * .21, 1.05);
    cloud(s.width * .81, s.height * .39, .73);
    cloud(s.width * .37, s.height * .51, .68);

    void hill(double y, Color color, double lift) {
      final p = Path()
        ..moveTo(0, s.height)
        ..lineTo(0, y)
        ..cubicTo(s.width * .21, y - lift, s.width * .30, y + lift,
            s.width * .53, y)
        ..cubicTo(s.width * .74, y - lift, s.width * .93, y - lift * .6,
            s.width, y + 8)
        ..lineTo(s.width, s.height)
        ..close();
      c.drawPath(p, Paint()..color = color);
    }
    hill(s.height * .78, const Color(0xFFBFF4AE), 68);
    hill(s.height * .86, const Color(0xFF85DB9A), 51);
    hill(s.height * .94, const Color(0xFF55C89E), 39);

    final sprinkle = Paint()..color = const Color(0xAAFFFFFF);
    final points = <Offset>[
      Offset(.11, .12), Offset(.29, .33), Offset(.94, .12),
      Offset(.12, .61), Offset(.69, .52), Offset(.62, .13),
      Offset(.41, .68), Offset(.91, .66),
    ];
    for (final p in points) {
      final center = Offset(p.dx * s.width, p.dy * s.height);
      c.drawCircle(center, 4, sprinkle);
      c.drawCircle(center, 8,
          Paint()..color = const Color(0x55FFFFFF)
            ..style = PaintingStyle.stroke..strokeWidth = 2);
    }
    // Stationary soft bokeh: no extra GPU animation while a match resolves.
    for (var i = 0; i < 15; i++) {
      final x = ((i * 43 + 31) % 101) / 101 * s.width;
      final y = ((i * 67 + 13) % 97) / 97 * s.height;
      final radius = 4.0 + (i % 3) * 2.6;
      c.drawCircle(Offset(x, y), radius,
          Paint()..color = const Color(0x33FFFFFF));
      c.drawCircle(Offset(x - radius * .2, y - radius * .2),
          radius * .23, Paint()..color = const Color(0x88FFFFFF));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Distinct match explosion with expanding rings, candy fragments, streaks and
/// white flashes. Deterministic and rendered on a single canvas for smooth FPS.
class SparklePainter extends CustomPainter {
  SparklePainter({required this.progress, required this.centers, required this.colors});
  final double progress;
  final List<Offset> centers;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    if (centers.isEmpty || p >= 1) return;
    final fade = (1 - p);
    final flash = (1 - p * 5).clamp(0.0, 1.0);
    if (flash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = Colors.white.withValues(alpha: flash * .14));
    }
    // The particle budget is capped so even large chain reactions stay fluid.
    final visibleCenters = centers.length <= 14
        ? centers : [for (var i = 0; i < 14; i++) centers[i * centers.length ~/ 14]];
    for (var j = 0; j < visibleCenters.length; j++) {
      final center = visibleCenters[j];
      final base = colors[j % colors.length];
      final ring = 6 + Curves.easeOutCubic.transform(p) * 46;
      final ringOpacity = (.92 * fade).clamp(0.0, 1.0);
      canvas.drawCircle(center, ring, Paint()
        ..color = Colors.white.withValues(alpha: ringOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.3 * fade + .4);
      canvas.drawCircle(center, ring * .72, Paint()
        ..color = base.withValues(alpha: .78 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0 * fade + .4);
      if (p < .44) {
        final hot = (1 - p / .44).clamp(0.0, 1.0);
        canvas.drawCircle(center, 9 + p * 37,
          Paint()..shader = RadialGradient(colors: [
            Colors.white.withValues(alpha: .95 * hot),
            base.withValues(alpha: .58 * hot),
            base.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: center, radius: 31)));
      }
      for (var i = 0; i < 12; i++) {
        final angle = i * math.pi / 6 + j * .77;
        final speed = 31.0 + (i % 4) * 11;
        final d = 7 + Curves.easeOut.transform(p) * speed;
        final position = Offset(center.dx + math.cos(angle) * d,
            center.dy + math.sin(angle) * d + p * p * 13);
        final radius = (6.4 * fade).clamp(.2, 6.4);
        final color = i.isEven ? Colors.white :
            candyPalette[(j + i) % candyPalette.length];
        canvas.drawCircle(position, radius * .85,
          Paint()..color = color.withValues(alpha: (.96 * fade).clamp(0.0, 1.0)));
        // The bright streak travels out with each candy fragment.
        final tail = Offset(position.dx - math.cos(angle) * (12 * fade),
          position.dy - math.sin(angle) * (12 * fade));
        canvas.drawLine(position, tail, Paint()
          ..color = color.withValues(alpha: .78 * fade)
          ..strokeWidth = (3.0 * fade).clamp(.2, 3.0)
          ..strokeCap = StrokeCap.round);
        if (i % 3 == 0) {
          final star = Path()
            ..moveTo(position.dx, position.dy - radius * 2.6)
            ..lineTo(position.dx + radius * .55, position.dy)
            ..lineTo(position.dx, position.dy + radius * 2.6)
            ..lineTo(position.dx - radius * .55, position.dy)
            ..close();
          canvas.drawPath(star, Paint()
            ..color = Colors.white.withValues(alpha: .88 * fade));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SparklePainter old) =>
      progress != old.progress || centers != old.centers || colors != old.colors;
}
