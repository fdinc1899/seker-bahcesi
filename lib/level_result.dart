import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Full-screen celebration/result view, placed over the current match board.
/// All progress and booster rewards are awarded by the parent BEFORE this
/// widget is shown. Rebuilding this animation never grants rewards twice.
class LevelResultOverlay extends StatefulWidget {
  const LevelResultOverlay({
    super.key,
    required this.won,
    required this.level,
    required this.score,
    required this.stars,
    required this.lastLevel,
    required this.bonusShuffle,
    required this.onPrimary,
    required this.onMap,
  });

  final bool won;
  final int level;
  final int score;
  final int stars;
  final bool lastLevel;
  final bool bonusShuffle;
  final VoidCallback onPrimary;
  final VoidCallback onMap;

  @override
  State<LevelResultOverlay> createState() => _LevelResultOverlayState();
}

class _LevelResultOverlayState extends State<LevelResultOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1850),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant LevelResultOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.level != oldWidget.level || widget.won != oldWidget.won) {
      _animation.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  double _stagger(double start, double duration) =>
      ((_animation.value - start) / duration).clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    final gold = widget.won;
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: gold ? const Color(0xD956176D) : const Color(0xC936205E),
          ),
        ),
        if (gold)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(progress: _animation.value),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 17, vertical: 12),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    final appearance = Curves.easeOutBack.transform(
                        _stagger(0, .42));
                    return Opacity(
                      opacity: _stagger(0, .26),
                      child: Transform.scale(
                        scale: .84 + .16 * appearance,
                        child: _resultCard(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultCard() {
    final win = widget.won;
    return Container(
      width: 360,
      padding: const EdgeInsets.fromLTRB(17, 24, 17, 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFF0F7), Color(0xFFFFE2F0)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFE08A), width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0xA92F1251),
            blurRadius: 30,
            spreadRadius: 2,
            offset: Offset(0, 13),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(win ? 'TEBRİKLER!' : 'TEKRAR DENE!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: win ? const Color(0xFFE8338A) :
                    const Color(0xFF8F4AAB),
                fontSize: 30,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(color: Colors.white, offset: Offset(-1, -2)),
                  Shadow(color: Color(0x66562272), blurRadius: 5,
                      offset: Offset(2, 4)),
                ],
              )),
          const SizedBox(height: 4),
          Text(win ? 'ŞEKER ŞÖLENİ!' : 'YENİDEN BAŞARABİLİRSİN',
              style: const TextStyle(
                letterSpacing: 1.1,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF944FB1),
              )),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final earned = win && index < widget.stars;
              final reveal = _stagger(.15 + index * .17, .30);
              final scale = earned
                  ? .05 + .95 * Curves.elasticOut.transform(reveal)
                  : 1.0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.scale(
                  scale: scale,
                  child: Icon(Icons.star_rounded,
                    key: ValueKey('result-star-$index'),
                    color: earned ? const Color(0xFFFFBE24) :
                        const Color(0xFFD3C3D9),
                    size: 68,
                    shadows: earned
                        ? const [Shadow(color: Color(0xAAFFA52B),
                            blurRadius: 13, offset: Offset(0, 3))]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(win
                  ? '${widget.level}. bölümü tamamladın!'
                  : 'Hamlelerin bitti. Bir kez daha dene!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7A408B),
                  fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFCE6F), width: 1.5),
            ),
            child: Text('🏆 ${widget.score} PUAN',
                style: const TextStyle(color: Color(0xFFBE7430),
                    fontSize: 18, fontWeight: FontWeight.w900)),
          ),
          if (win && widget.bonusShuffle) ...[
            const SizedBox(height: 13),
            Container(
              key: const ValueKey('three-star-prize'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFFFCE1FF), Color(0xFFFFF3B8),
                ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE6A5F3), width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard_rounded, color: Color(0xFF9A38C5)),
                  SizedBox(width: 7),
                  Flexible(child: Text('3 YILDIZ ÖDÜLÜ: +1 KARIŞTIR',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w900,
                          color: Color(0xFF8F369F), fontSize: 12))),
                ],
              ),
            ),
          ],
          if (!win) ...[
            const SizedBox(height: 10),
            const Text('İpucu: 4 veya 5 şeker eşleştirip özel güç kazan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: Color(0xFF9A6A9F))),
          ],
          const SizedBox(height: 22),
          _resultButton(
            win
                ? (widget.lastLevel ? 'BÖLÜM HARİTASI' : 'SONRAKİ BÖLÜM')
                : 'YENİDEN DENE',
            widget.onPrimary,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: widget.onMap,
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('Bölüm haritasına dön',
                style: TextStyle(fontWeight: FontWeight.w800)),
            style: TextButton.styleFrom(foregroundColor:
                const Color(0xFF9750AC)),
          ),
        ],
      ),
    );
  }

  Widget _resultButton(String label, VoidCallback callback) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: callback,
          borderRadius: BorderRadius.circular(19),
          child: Ink(
            height: 57,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFFFFD85B), Color(0xFFFF8C47),
              ]),
              border: Border.all(color: const Color(0xFFFFE9A8), width: 3),
              borderRadius: BorderRadius.circular(19),
              boxShadow: const [BoxShadow(color: Color(0x55D34B71),
                  blurRadius: 9, offset: Offset(0, 4))],
            ),
            child: Center(child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white,
                    fontSize: 19, fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Color(0x883A164D),
                        blurRadius: 3, offset: Offset(1, 2))]))),
          ),
        ),
      );
}

/// Confetti uses stable per-particle seeds for an identical trajectory on
/// every frame. The user can still tap the card while it runs.
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress});
  final double progress;
  static const _palette = [
    Color(0xFFFFCA3A), Color(0xFFFC4AA0), Color(0xFF64E8F7),
    Color(0xFF9EEA62), Color(0xFFBE83FF), Color(0xFFFFFFFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(24);
    for (var i = 0; i < 96; i++) {
      final phase = rng.nextDouble() * .47;
      final startX = rng.nextDouble() * size.width;
      final drift = (rng.nextDouble() - .5) * 150;
      final spin = rng.nextDouble() * 6;
      final width = 3.5 + rng.nextDouble() * 7;
      final height = 5 + rng.nextDouble() * 12;
      final value = ((progress - phase) / (1 - phase))
          .clamp(0.0, 1.0).toDouble();
      if (value == 0) continue;
      final opacity = (math.min(1.0, value * 8) *
          (1 - math.max(0.0, (value - .83) / .17)))
          .clamp(0.0, 1.0).toDouble();
      final dx = startX + drift * value + math.sin(value * 12 + spin) * 11;
      final dy = -30 + value * (size.height + 85);
      final paint = Paint()
        ..color = _palette[i % _palette.length].withValues(alpha: opacity);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(spin + value * 8);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: width, height: height),
        const Radius.circular(2.0)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
