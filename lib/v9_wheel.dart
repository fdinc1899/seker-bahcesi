import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'v9_rewards.dart';

/// Animated, offline wheel. Rewards are granted by the caller before spinning.
class V9WheelDialog extends StatefulWidget {
  const V9WheelDialog({super.key, required this.progress, required this.onSpin});
  final V9RewardsProgress progress;
  final V9WheelReward? Function(int slot) onSpin;

  @override
  State<V9WheelDialog> createState() => _V9WheelDialogState();
}

class _V9WheelDialogState extends State<V9WheelDialog> {
  bool _spinning = false;
  int? _prize;
  double _angle = 0;

  @override
  void initState() {
    super.initState();
    _prize = widget.progress.wheelIndex;
    if (_prize != null) _angle = -2 * math.pi * _prize! / 6;
  }

  Future<void> _spin() async {
    if (_spinning || !widget.progress.canSpin(DateTime.now())) return;
    final slot = math.Random().nextInt(v9WheelRewards.length);
    final reward = widget.onSpin(slot);
    if (reward == null) return;
    setState(() {
      _spinning = true;
      _prize = slot;
      // Each sector is drawn around its index angle. Rotate the chosen
      // sector toward the stationary pointer at the top of the wheel.
      _angle = 12 * math.pi - 2 * math.pi * slot / 6;
    });
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    if (mounted) setState(() => _spinning = false);
  }

  @override
  Widget build(BuildContext context) {
    final reward = _prize == null ? null : v9WheelRewards[_prize!];
    return AlertDialog(
      key: const ValueKey('v9-wheel-dialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      backgroundColor: const Color(0xFFFFF5FB),
      title: const Text('🎡 GÜNLÜK ŞANS ÇARKI',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900,
              fontSize: 19, color: Color(0xFF8534A5))),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.arrow_drop_down_rounded,
          size: 34, color: Color(0xFFEC448B)),
        SizedBox(width: 228, height: 228, child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: _angle),
          duration: Duration(milliseconds: _spinning ? 2300 : 0),
          curve: Curves.easeOutCubic,
          builder: (context, angle, _) => Transform.rotate(
            angle: angle,
            child: CustomPaint(painter: _WheelPainter()),
          ),
        )),
        const SizedBox(height: 12),
        Text(_spinning ? 'Çark dönüyor...' : reward == null
            ? 'Bugünkü ücretsiz hakkını kullan!'
            : 'ÖDÜL: ${reward.name}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800,
              color: Color(0xFF843C96))),
        const SizedBox(height: 9),
        FilledButton.icon(
          key: const ValueKey('v9-spin-button'),
          onPressed: widget.progress.canSpin(DateTime.now()) && !_spinning
              ? _spin : null,
          icon: const Icon(Icons.autorenew_rounded),
          label: Text(widget.progress.canSpin(DateTime.now())
              ? 'ÜCRETSİZ ÇEVİR' : 'BUGÜN ÇEVRİLDİ ✓'),
        ),
        const SizedBox(height: 6),
        const Text('Günde bir ücretsiz çevirme • Çevrim dışı',
          style: TextStyle(fontSize: 11, color: Color(0xFF8C668F))),
      ]),
      actions: [TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('KAPAT'))],
    );
  }
}

class _WheelPainter extends CustomPainter {
  static const _colors = <Color>[
    Color(0xFFFF79A4), Color(0xFF9A7CF7), Color(0xFFFFC864),
    Color(0xFF6EDACB), Color(0xFFFF9D72), Color(0xFF89BFFF),
  ];
  static const _labels = <String>['50 🍬', '🔨', '100 🍬', '🔀', '150 🍬', '⚡'];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * math.pi / 6;
    for (var i = 0; i < 6; i++) {
      // Sector 0 is centered at the top; increasing indices go clockwise.
      final start = -math.pi / 2 - sweep / 2 + i * sweep;
      canvas.drawArc(rect, start, sweep, true,
        Paint()..color = _colors[i]);
      final angle = -math.pi / 2 + i * sweep;
      final loc = center + Offset(math.cos(angle), math.sin(angle)) * radius * .64;
      final painter = TextPainter(
        text: TextSpan(text: _labels[i],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
            color: Colors.white, shadows: [Shadow(color: Color(0x99000000),
                blurRadius: 3)])),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, loc - Offset(painter.width / 2, painter.height / 2));
    }
    canvas.drawCircle(center, radius,
      Paint()..style = PaintingStyle.stroke..color = Colors.white..strokeWidth = 7);
    canvas.drawCircle(center, 17, Paint()..color = Colors.white);
    canvas.drawCircle(center, 10, Paint()..color = const Color(0xFFB049A6));
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => false;
}
