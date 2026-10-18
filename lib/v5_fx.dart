import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pure visual layer for V5: no gameplay mutations, assets or dependencies.
class V5ScorePainter extends CustomPainter {
  const V5ScorePainter({
    required this.progress,
    required this.centers,
    required this.points,
    required this.chain,
  });

  final double progress;
  final List<Offset> centers;
  final int points;
  final int chain;

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.isEmpty || size.isEmpty || points <= 0) return;
    final p = progress.clamp(0.0, 1.0).toDouble();
    if (p >= .9) return;
    var middle = Offset.zero;
    for (final offset in centers) {
      middle += offset;
    }
    middle /= centers.length.toDouble();
    final a = (1 - p / .9).clamp(0.0, 1.0).toDouble();
    final fly = Curves.easeOutCubic.transform(p);
    final label = chain > 1 ? '+$points  x$chain' : '+$points';
    final text = TextPainter(
      text: TextSpan(text: label,
        style: TextStyle(
          color: const Color(0xFFFFF6AC).withValues(alpha: a),
          fontSize: chain >= 3 ? 31 : 26,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(color: const Color(0xFF631B86).withValues(alpha: a),
              offset: const Offset(2, 3), blurRadius: 4),
            Shadow(color: const Color(0xFFF97421).withValues(alpha: a),
              blurRadius: 9),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * .84);
    final at = Offset(
      (middle.dx - text.width / 2).clamp(5.0, math.max(5, size.width - text.width - 5)).toDouble(),
      (middle.dy - 14 - fly * 50).clamp(4.0, math.max(4, size.height - text.height - 4)).toDouble(),
    );
    text.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant V5ScorePainter old) =>
      old.progress != progress || old.points != points ||
      old.chain != chain || old.centers != centers;
}

/// Lightweight deterministic, full-screen confetti for a won level.
class V5CelebrationPainter extends CustomPainter {
  const V5CelebrationPainter({required this.progress});
  final double progress;

  static const _palette = <Color>[
    Color(0xFFFFD34E), Color(0xFFFF5D95), Color(0xFF55E1F9),
    Color(0xFFAB6AFF), Color(0xFF7CF48A), Color(0xFFFFFFFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final p = progress.clamp(0.0, 1.0).toDouble();
    if (p >= 1) return;
    final opacity = (1 - (p - .77).clamp(0.0, .23) / .23)
        .clamp(0.0, 1.0).toDouble();
    for (var i = 0; i < 84; i++) {
      final seeded = (i * 41 + 17) % 101 / 101.0;
      final speed = .58 + (i % 8) * .083;
      final x = (seeded * size.width +
        math.sin(p * 11 + i * .87) * (12 + i % 9)).toDouble();
      final y = -50 - (i % 6) * 29 +
          p * (size.height + 250) * speed;
      if (y < -25 || y > size.height + 25) continue;
      final width = 5.5 + (i % 4) * 2.0;
      final height = 10.0 + (i % 5) * 2.5;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p * 13 + i * 1.9);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: width, height: height),
          const Radius.circular(2)),
        Paint()..color = _palette[i % _palette.length]
          .withValues(alpha: .92 * opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant V5CelebrationPainter old) =>
      old.progress != progress;
}
