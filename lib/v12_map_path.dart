import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A decorative, winding road behind the existing interactive level widgets.
/// Positions are deterministic so levels don't jump after rebuilds.
class V12PathGeometry {
  static const double height = 1125;

  static Offset levelCenter(int index, double width) {
    final phase = index * math.pi / 3.6;
    final x = width * (.50 + math.sin(phase) * .31);
    return Offset(x, 43 + index * 54);
  }
}

class V12RoadPainter extends CustomPainter {
  const V12RoadPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final path = Path();
    for (var i = 0; i < 20; i++) {
      final point = V12PathGeometry.levelCenter(i, size.width);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        final prev = V12PathGeometry.levelCenter(i - 1, size.width);
        final middle = (point.dy + prev.dy) / 2;
        path.cubicTo(prev.dx, middle, point.dx, middle, point.dx, point.dy);
      }
    }
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 37
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x884A2651));
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFE5AA));
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 23
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFF7D9));
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFC777));

    final flower = Paint()..color = const Color(0xFFE849A4);
    final middle = Paint()..color = const Color(0xFFFFD55D);
    for (var i = 0; i < 36; i++) {
      final x = size.width * (.09 + .82 * ((i * 17 % 101) / 101));
      final y = 25 + i * 30.3;
      for (var petal = 0; petal < 5; petal++) {
        final a = petal * math.pi * 2 / 5;
        canvas.drawCircle(Offset(x + 5 * math.cos(a), y + 5 * math.sin(a)),
            3.5, flower);
      }
      canvas.drawCircle(Offset(x, y), 3.3, middle);
    }
  }

  @override
  bool shouldRepaint(covariant V12RoadPainter oldDelegate) => false;
}
