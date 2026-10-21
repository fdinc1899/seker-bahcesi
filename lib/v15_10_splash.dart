// V1512_SPLASH_FIX: one clean premium introduction, no game state changes.
import 'dart:math' as math;
import 'package:flutter/material.dart';

class V1510PremiumSplash extends StatefulWidget {
  const V1510PremiumSplash({super.key});

  @override
  State<V1510PremiumSplash> createState() => _PremiumLoadingState();
}

class _PremiumLoadingState extends State<V1510PremiumSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glimmer;

  @override
  void initState() {
    super.initState();
    _glimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat();
  }

  @override
  void dispose() {
    _glimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF8AD6F4),
      child: Stack(fit: StackFit.expand, children: <Widget>[
        Image.asset(
          'assets/images/v15_12_splash_world.webp',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
        // No duplicate logo or painted loading bar.
        // This real Flutter progress bar is drawn on a softened part of the artwork.
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 64),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: .04, end: .92),
                    duration: const Duration(milliseconds: 1700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Container(
                      height: 23,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF752A83),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: const Color(0xFFFFDB79), width: 2.4),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(color: Color(0x9943216D), blurRadius: 11,
                            offset: Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: const Color(0xFF67236F),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF62B2)),
                          minHeight: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Şekerler yükleniyor...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20, color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .2,
                      shadows: <Shadow>[
                        Shadow(color: Color(0xFF53185E), blurRadius: 5,
                          offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _glimmer,
            builder: (context, child) => CustomPaint(
              painter: _V1512Shimmer(_glimmer.value),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ]),
    );
  }
}

class _V1512Shimmer extends CustomPainter {
  const _V1512Shimmer(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    const positions = <Offset>[
      Offset(.12, .25), Offset(.87, .27), Offset(.18, .54),
      Offset(.81, .61), Offset(.23, .70), Offset(.78, .75),
    ];
    for (var i = 0; i < positions.length; i++) {
      final t = (.5 + .5 * math.sin(value * math.pi * 2 + i * 1.35));
      final r = 2.0 + t * 3.0;
      final x = size.width * positions[i].dx;
      final y = size.height * positions[i].dy;
      final p = Paint()
        ..color = Colors.white.withOpacity(.18 + .6 * t)
        ..strokeWidth = 1.3;
      canvas.drawLine(Offset(x-r, y), Offset(x+r, y), p);
      canvas.drawLine(Offset(x, y-r), Offset(x, y+r), p);
    }
  }

  @override
  bool shouldRepaint(covariant _V1512Shimmer oldDelegate) =>
      oldDelegate.value != value;
}
