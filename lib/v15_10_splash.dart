// V1510_PREMIUM_SPLASH / V1511_CANDY_SPLASH_REDESIGN
// Brand-only presentation. Do not change game state, sound, or save data.
import 'dart:math' as math;
import 'package:flutter/material.dart';

class V1510PremiumSplash extends StatefulWidget {
  const V1510PremiumSplash({super.key});

  @override
  State<V1510PremiumSplash> createState() => _V1510PremiumSplashState();
}

class _V1510PremiumSplashState extends State<V1510PremiumSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF93D7F7),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // A single fully composed illustration; avoid overlapping logos or banners.
          Image.asset(
            'assets/images/v15_11_splash_art.webp',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) => CustomPaint(
                painter: _V1511Glints(_animation.value),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _V1511Glints extends CustomPainter {
  const _V1511Glints(this.phase);
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    // Tiny ambient twinkles. No expensive shaders or image compositing.
    final centers = <Offset>[
      const Offset(.13, .17), const Offset(.87, .29),
      const Offset(.19, .46), const Offset(.77, .52),
      const Offset(.27, .72), const Offset(.85, .79),
    ];
    for (var i = 0; i < centers.length; i++) {
      final twinkle = .5 + .5 * math.sin((phase * math.pi * 2) + i * 1.8);
      final paint = Paint()
        ..color = Colors.white.withOpacity(.15 + .65 * twinkle)
        ..strokeWidth = 1.6;
      final x = centers[i].dx * size.width;
      final y = centers[i].dy * size.height;
      final r = 2 + 4 * twinkle;
      canvas.drawLine(Offset(x-r,y), Offset(x+r,y), paint);
      canvas.drawLine(Offset(x,y-r), Offset(x,y+r), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _V1511Glints oldDelegate) => oldDelegate.phase != phase;
}
