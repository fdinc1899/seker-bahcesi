// V1510_PREMIUM_SPLASH - startup presentation only; no game/save logic.
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated visual shown briefly as Flutter's first route becomes ready.
class V1510PremiumSplash extends StatefulWidget {
  const V1510PremiumSplash({super.key});

  @override
  State<V1510PremiumSplash> createState() => _V1510PremiumSplashState();
}

class _V1510PremiumSplashState extends State<V1510PremiumSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..forward();
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1B4D6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/v15_10_splash_world.webp',
            fit: BoxFit.cover, filterQuality: FilterQuality.high),
          const DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0x3373237D), Color(0x00000000), Color(0x661B164B)],
              stops: [0, .47, 1],
            ),
          )),
          AnimatedBuilder(
            animation: _glow,
            builder: (context, child) => Align(
              alignment: const Alignment(0, -0.21),
              child: Transform.scale(
                scale: 0.98 + _glow.value * .045,
                child: child,
              ),
            ),
            child: FractionallySizedBox(
              widthFactor: .89,
              child: Image.asset('assets/images/v15_10_splash_logo.png',
                fit: BoxFit.contain, filterQuality: FilterQuality.high,
                semanticLabel: 'Şeker Bahçesi'),
            ),
          ),
          AnimatedBuilder(
            animation: _glow,
            builder: (context, child) => CustomPaint(
              painter: _V1510SparklePainter(_glow.value),
              child: const SizedBox.expand(),
            ),
          ),
          Align(
            alignment: const Alignment(0, .76),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 17),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFFFDF0F7), Color(0xFFFFE8D5),
                    ]),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFFFD16F), width: 2.5),
                    boxShadow: const [BoxShadow(
                      color: Color(0x885C267A), blurRadius: 17,
                      offset: Offset(0, 6),
                    )],
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('ŞEKER DİYARI YÜKLENİYOR',
                        style: TextStyle(
                          fontSize: 15, color: Color(0xFF84306F),
                          fontWeight: FontWeight.w900, letterSpacing: .4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 8,
                        child: AnimatedBuilder(
                          animation: _glow,
                          builder: (context, child) => LinearProgressIndicator(
                            value: .22 + .65 * _glow.value,
                            backgroundColor: const Color(0xFFEBD1E9),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFF350AA)),
                            minHeight: 8,
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _V1510SparklePainter extends CustomPainter {
  const _V1510SparklePainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[
      const Offset(.14, .26), const Offset(.81, .28),
      const Offset(.19, .56), const Offset(.85, .63),
      const Offset(.35, .72), const Offset(.70, .48),
    ];
    final paint = Paint()..color = const Color(0xEFFFFFCE);
    for (var i = 0; i < points.length; i++) {
      final x = points[i].dx * size.width;
      final y = points[i].dy * size.height;
      final r = 3.0 + (math.sin(progress * math.pi * 2 + i) + 1) * 2.6;
      paint.strokeWidth = 2;
      canvas.drawLine(Offset(x-r,y), Offset(x+r,y), paint);
      canvas.drawLine(Offset(x,y-r), Offset(x,y+r), paint);
      canvas.drawCircle(Offset(x,y), 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _V1510SparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
