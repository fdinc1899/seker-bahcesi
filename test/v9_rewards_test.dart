import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/v9_rewards.dart';

void main() {
  final today = DateTime(2026, 10, 19);
  final tomorrow = DateTime(2026, 10, 20);

  test('Free spin works once per day even after save reload', () {
    final state = V9RewardsProgress(today: today);
    expect(state.canSpin(today), isTrue);
    expect(state.spin(1, today)?.hammers, 1);
    expect(state.canSpin(today), isFalse);
    expect(state.spin(2, today), isNull);
    final restored = V9RewardsProgress.fromJson(state.toJson(), today);
    expect(restored.canSpin(today), isFalse);
    expect(restored.totalSpins, 1);
    expect(restored.spin(4, tomorrow)?.coins, 150);
    expect(restored.totalSpins, 2);
  });

  test('Prize index is validated before consuming spin', () {
    final state = V9RewardsProgress(today: today);
    expect(state.spin(-1, today), isNull);
    expect(state.spin(6, today), isNull);
    expect(state.canSpin(today), isTrue);
    expect(state.spin(5, today)?.lines, 1);
  });

  test('Collection grows for valid cleared candy colors only', () {
    final state = V9RewardsProgress(today: today);
    state.recordWave([0, 0, 5, 99, -1]);
    expect(state.colorCounts, [2, 0, 0, 0, 0, 1]);
    expect(state.claimColor(0), isNull);
    state.recordWave(List<int>.filled(43, 0));
    expect(state.claimColor(0), 100);
    expect(state.claimColor(0), isNull);
    expect(state.claimColor(6), isNull);
  });

  test('Collection stays after date changes and roundtrip', () {
    final progress = V9RewardsProgress(today: today);
    progress.recordWave(List<int>.filled(45, 2));
    expect(progress.claimColor(2), 100);
    progress.spin(3, today);
    final next = V9RewardsProgress.fromJson(progress.toJson(), tomorrow);
    expect(next.canSpin(tomorrow), isTrue);
    expect(next.colorCounts[2], 45);
    expect(next.claimColor(2), isNull);
  });

  test('Corrupt save values are bounded and do not crash', () {
    final restored = V9RewardsProgress.fromJson({
      'day': v9DayKey(today),
      'wheelIndex': 100,
      'totalSpins': -99,
      'colors': [99999999, -2, 'bad', null, 30, 2],
      'collectionClaims': [0, -2, 99, '4'],
    }, today);
    expect(restored.canSpin(today), isTrue);
    expect(restored.totalSpins, 0);
    expect(restored.colorCounts, [1000000, 0, 0, 0, 30, 2]);
    expect(restored.collectionClaims, {0});
  });
}
