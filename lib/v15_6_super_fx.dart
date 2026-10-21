import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pure visual tiers, isolated from scoring, rewards and save data.
/// Chain reactions take priority over the initial match length.
int v156BurstTier(int count, int chain) {
  if (chain > 1) return 4;
  if (count >= 5) return 3;
  if (count == 4) return 2;
  return count >= 3 ? 1 : 0;
}

String v156Celebration(int count, int chain) {
  if (chain > 1) return 'SÜPER KOMBO x$chain!';
  if (count >= 5) return 'MUHTEŞEM!';
  if (count == 4) return 'MÜKEMMEL!';
  return count >= 3 ? 'HARİKA!' : '';
}

/// No GestureDetectors here: original game board remains responsible for input.
class V156ComboBanner extends StatelessWidget {
  const V156ComboBanner({
    super.key,
    required this.text,
    required this.progress,
    required this.boardSize,
    required this.tier,
  });

  final String text;
  final double progress;
  final double boardSize;
  final int tier;

  @override
  Widget build(BuildContext context) {
    final premium = tier >= 3;
    final surge = math.sin(progress.clamp(0.0, 1.0).toDouble() * math.pi);
    return Transform.rotate(
      angle: .016 * math.sin(progress * math.pi * 3),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: boardSize * .94),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(colors: premium
                ? const [Color(0xFFFFA633), Color(0xFFFF559D), Color(0xFFA13ED8)]
                : const [Color(0xFFFA58A7), Color(0xFFB83CC6)]),
            border: Border.all(color: const Color(0xFFFFF1AB), width: 2.3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD04D)
                    .withValues(alpha: .25 + .50 * surge),
                blurRadius: 10 + surge * 20,
                spreadRadius: 1 + surge * 3,
              ),
              const BoxShadow(color: Color(0x773B155A), blurRadius: 9,
                  offset: Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontSize: boardSize * .084,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: Color(0xFF651973), blurRadius: 4,
                        offset: Offset(1.5, 2.5)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lightweight deterministic candy-particle overlay driven by the preexisting
/// 820ms animation; no timers, random streams, audio, or saved state.
class V156SuperBurstPainter extends CustomPainter {
  const V156SuperBurstPainter({
    required this.progress,
    required this.centers,
    required this.colors,
    required this.tier,
  });

  final double progress;
  final List<Offset> centers;
  final List<Color> colors;
  final int tier;

  @override
  void paint(Canvas canvas, Size size) {
    if (tier < 1 || centers.isEmpty || size.isEmpty) return;
    final p = progress.clamp(0.0, 1.0).toDouble();
    if (p > .96) return;
    final fade = (1.0 - p / .96).clamp(0.0, 1.0).toDouble();
    final active = centers.length > 16 ? centers.take(16).toList() : centers;
    final sparkCount = tier == 1 ? 5 : tier == 2 ? 7 : 9;
    final explosion = Curves.easeOutCubic.transform(p);
    final warm = const Color(0xFFFFF2AA);

    // Every match creates a soft expanding ring and a few flying sparkles.
    for (var index = 0; index < active.length; index++) {
      final origin = active[index];
      final candyColor = colors.isEmpty ? warm : colors[index % colors.length];
      if (index < (tier >= 3 ? 10 : 7)) {
        final radius = (5 + 20 * explosion) * (tier >= 3 ? 1.15 : 1.0);
        canvas.drawCircle(origin, radius, Paint()
          ..color = warm.withValues(alpha: .55 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8 * fade + .3);
      }
      for (var i = 0; i < sparkCount; i++) {
        final angle = (i * 2 * math.pi / sparkCount) + (index * .77);
        final distance = 4 + explosion * (15 + tier * 5 + i % 3 * 5);
        final at = origin + Offset(math.cos(angle), math.sin(angle)) * distance;
        final color = i.isEven ? warm : candyColor;
        _drawGlint(canvas, at, 1.5 + tier * .4 + (i % 3), fade, color);
      }
    }

    // Four/five matches and cascades throw a short-lived star shower across
    // the board. The deterministic pattern is stable on every repaint.
    if (tier >= 2) {
      final n = tier == 2 ? 15 : tier == 3 ? 27 : 36;
      for (var i = 0; i < n; i++) {
        final seedX = ((i * 43 + 17) % 101) / 101.0;
        final seedY = ((i * 73 + 11) % 103) / 103.0;
        final flutter = math.sin(p * math.pi * 4 + i * 1.2) * 6;
        final at = Offset(size.width * seedX + flutter,
            size.height * seedY + p * (25 + i % 6 * 10));
        final alpha = math.sin(math.pi * p).clamp(0.0, 1.0).toDouble() * .8 * fade;
        _drawGlint(canvas, at, 2.2 + (i % 4), alpha,
            i.isEven ? warm : const Color(0xFFFF72D2));
      }
    }
  }

  static void _drawGlint(Canvas canvas, Offset at, double radius,
      double opacity, Color color) {
    if (opacity <= .01) return;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0).toDouble())
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (1.1 + radius * .22) * opacity;
    canvas.drawLine(at.translate(-radius, 0), at.translate(radius, 0), paint);
    canvas.drawLine(at.translate(0, -radius), at.translate(0, radius), paint);
    canvas.drawCircle(at, math.max(.65, radius * .22),
        Paint()..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0).toDouble()));
  }

  @override
  bool shouldRepaint(covariant V156SuperBurstPainter old) =>
      old.progress != progress || old.tier != tier ||
      old.centers != centers || old.colors != colors;
}
