import 'dart:math' as math;
import 'package:flutter/material.dart';

const candyPalette = <Color>[
  Color(0xFF20BCFF), // blue drop
  Color(0xFFFF477C), // strawberry jelly
  Color(0xFF68D94D), // lime candy
  Color(0xFFFFD342), // lemon star
  Color(0xFFFF9635), // striped caramel
  Color(0xFFA96CFF), // berry cluster
];

class CandyPiece extends StatelessWidget {
  const CandyPiece({super.key, required this.type, required this.size});
  final int type;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: CandyPainter(type),
      );
}

class CandyPainter extends CustomPainter {
  CandyPainter(this.type);
  final int type;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final base = candyPalette[type % candyPalette.length];
    final dark = Color.lerp(base, Colors.black, .30)!;
    final pale = Color.lerp(base, Colors.white, .62)!;
    final shadow = Paint()
      ..color = const Color(0xAA37145B)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(const Rect.fromLTWH(15, 76, 75, 15), shadow);

    Paint fill(Rect rect) => Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.52, -.70),
        radius: 1.12,
        colors: [Colors.white, pale, base, dark],
        stops: const [0, .18, .62, 1],
      ).createShader(rect);

    final outline = Paint()
      ..color = dark.withValues(alpha: .66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
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
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CandyPainter old) => old.type != type;
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class SparklePainter extends CustomPainter {
  SparklePainter({required this.progress, required this.centers, required this.colors});
  final double progress;
  final List<Offset> centers;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    for (var j = 0; j < centers.length; j++) {
      final center = centers[j];
      final color = colors[j % colors.length];
      for (var i = 0; i < 7; i++) {
        final a = i * 2 * math.pi / 7 + j * .4;
        final d = 10 + progress * 42;
        final pos = Offset(center.dx + math.cos(a) * d,
            center.dy + math.sin(a) * d);
        final radius = (4.5 * (1 - progress)).clamp(0.0, 4.5);
        canvas.drawCircle(pos, radius, Paint()
          ..color = color.withValues(alpha: 1 - progress));
      }
    }
  }

  @override
  bool shouldRepaint(covariant SparklePainter old) =>
      progress != old.progress || centers != old.centers;
}
