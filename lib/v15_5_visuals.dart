import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Visual-only V15.5 decorations. No gameplay or save state is modified.
/// Keeps all level hit targets in the original widget below the animation.
class V155CurrentLevelPulse extends StatefulWidget {
  const V155CurrentLevelPulse({super.key, required this.child});
  final Widget child;

  @override
  State<V155CurrentLevelPulse> createState() => _V155CurrentLevelPulseState();
}

class _V155CurrentLevelPulseState extends State<V155CurrentLevelPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      child: widget.child,
      builder: (context, child) {
        final amount = Curves.easeInOut.transform(_pulse.value);
        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 57 + amount * 8,
                  height: 57 + amount * 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFF4A3)
                          .withValues(alpha: .45 + amount * .53),
                      width: 2 + amount * 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC93D)
                            .withValues(alpha: .22 + amount * .37),
                        blurRadius: 9 + amount * 13,
                        spreadRadius: 2 + amount * 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Transform.scale(
              scale: 1 + amount * .055,
              child: child,
            ),
          ],
        );
      },
    );
  }
}

/// Tiny shimmering stars on a winding map. This layer is non-interactive.
class V155MapShimmer extends StatefulWidget {
  const V155MapShimmer({super.key});

  @override
  State<V155MapShimmer> createState() => _V155MapShimmerState();
}

class _V155MapShimmerState extends State<V155MapShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glimmer;

  @override
  void initState() {
    super.initState();
    _glimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3700),
    )..repeat();
  }

  @override
  void dispose() {
    _glimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glimmer,
        builder: (context, _) => CustomPaint(
          painter: V155MapShimmerPainter(_glimmer.value),
        ),
      ),
    );
  }
}

class V155MapShimmerPainter extends CustomPainter {
  const V155MapShimmerPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    for (var i = 0; i < 38; i++) {
      final nx = .08 + (((i * 47 + 19) % 83) / 83) * .84;
      final ny = .03 + (((i * 71 + 11) % 97) / 97) * .94;
      final point = Offset(size.width * nx, size.height * ny);
      final phase = progress * math.pi * 2 + i * 1.7;
      final intensity = math.pow(.5 + .5 * math.sin(phase), 3).toDouble();
      if (intensity < .12) continue;
      final ray = 2.4 + (i % 4) * .45 + intensity * 2;
      final paint = Paint()
        ..color = const Color(0xFFFFF8CB)
            .withValues(alpha: .22 + .65 * intensity)
        ..strokeWidth = .9 + intensity * .8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(point.translate(-ray, 0), point.translate(ray, 0), paint);
      canvas.drawLine(point.translate(0, -ray), point.translate(0, ray), paint);
      canvas.drawCircle(point, .8 + intensity, Paint()
        ..color = Colors.white.withValues(alpha: .4 + .58 * intensity));
    }
  }

  @override
  bool shouldRepaint(covariant V155MapShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Extra candy-burst glints, synchronized with the EXISTING burst controller.
class V155BurstGlitterPainter extends CustomPainter {
  const V155BurstGlitterPainter({required this.progress, required this.centers});
  final double progress;
  final List<Offset> centers;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || centers.isEmpty) return;
    final p = progress.clamp(0.0, 1.0).toDouble();
    if (p >= .82) return;
    final alpha = (1 - p / .82).clamp(0.0, 1.0).toDouble();
    // Cap painting work even on giant combo chains.
    for (final center in centers.take(30)) {
      for (var i = 0; i < 6; i++) {
        final angle = 2 * math.pi * i / 6 + .35;
        final distance = 4 + p * (24 + (i % 3) * 8);
        final at = center + Offset(math.cos(angle), math.sin(angle)) * distance;
        final size = (3.2 + (i % 2) * 1.5) * (1 - .55 * p);
        final color = i.isEven ? const Color(0xFFFFE367) : Colors.white;
        final paint = Paint()
          ..color = color.withValues(alpha: .95 * alpha)
          ..strokeWidth = 1.4 * alpha
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(at.translate(-size, 0), at.translate(size, 0), paint);
        canvas.drawLine(at.translate(0, -size), at.translate(0, size), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant V155BurstGlitterPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.centers != centers;
}
