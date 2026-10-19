import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/v9_rewards.dart';
import 'package:seker_bahcesi/v9_wheel.dart';

void main() {
  testWidgets('Wheel shows once-per-day button and consumes one spin',
      (tester) async {
    final now = DateTime.now();
    final progress = V9RewardsProgress(today: now);
    var prizesGiven = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
      child: V9WheelDialog(
        progress: progress,
        onSpin: (slot) {
          final reward = progress.spin(slot, now);
          if (reward != null) prizesGiven++;
          return reward;
        },
      ),
    ))));
    expect(find.byKey(const ValueKey('v9-wheel-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('v9-spin-button')));
    await tester.pump();
    expect(prizesGiven, 1);
    expect(progress.totalSpins, 1);
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('v9-spin-button')));
    expect(button.onPressed, isNull);
  });
}
