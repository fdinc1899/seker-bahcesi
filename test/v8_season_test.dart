import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/v8_season.dart';

void main() {
  final october = DateTime(2026, 10, 19);
  final november = DateTime(2026, 11, 1);

  test('Season changes at the beginning of the next month', () {
    expect(v8SeasonKey(october), '2026-10');
    expect(v8SeasonKey(november), '2026-11');
    final season = V8SeasonProgress(today: october);
    final oldTarget = season.targetType;
    season.recordWave(List.filled(60, oldTarget), 2, october);
    season.recordWin(10, october);
    expect(season.claim(V8Mission.colorHunt, october)?.coins, 180);
    season.advance(november);
    expect(season.collected, 0);
    expect(season.combos, 0);
    expect(season.finishedLevels, isEmpty);
    expect(season.claimed, isEmpty);
    expect(season.targetType, isNot(oldTarget));
  });

  test('Only target-colored matched candies are collected', () {
    final season = V8SeasonProgress(today: october);
    final target = season.targetType;
    season.recordWave([target, (target + 1) % 6, target], 1, october);
    expect(season.collected, 2);
    expect(season.combos, 0);
    season.recordWave([target], 2, october);
    expect(season.collected, 3);
    expect(season.combos, 1);
  });

  test('Season rewards can be claimed exactly once', () {
    final season = V8SeasonProgress(today: october);
    season.recordWave(List.filled(70, season.targetType), 3, october);
    expect(season.claim(V8Mission.colorHunt, october)?.coins, 180);
    expect(season.claim(V8Mission.colorHunt, october), isNull);
    for (var i = 0; i < 5; i++) {
      season.recordWave(const [], 2, october);
    }
    expect(season.claim(V8Mission.combos, october)?.hammers, 1);
    for (var i = 1; i <= 8; i++) {
      season.recordWin(i, october);
      season.recordWin(i, october);
    }
    expect(season.progressFor(V8Mission.levelWins), 8);
    expect(season.claim(V8Mission.levelWins, october)?.shuffles, 2);
  });

  test('Progress survives reload without touching V6/V7 save keys', () {
    final season = V8SeasonProgress(today: october);
    season.recordWave(List.filled(60, season.targetType), 2, october);
    season.recordWin(1, october);
    season.claim(V8Mission.colorHunt, october);
    final restored = V8SeasonProgress.fromJson(season.toJson(), october);
    expect(restored.collected, 60);
    expect(restored.combos, 1);
    expect(restored.finishedLevels, {1});
    expect(restored.claimed, {V8Mission.colorHunt});
    expect(V8SeasonProgress.fromJson(season.toJson(), november).collected, 0);
    expect(V8SeasonProgress.fromJson({}, october).collected, 0);
  });

  test('Corrupt and untrusted progress is bounded', () {
    final state = V8SeasonProgress.fromJson({
      'season': '2026-10',
      'collected': 999999999,
      'combos': -5,
      'levels': [-2, 0, 2, 2, 121, '4', 2.5],
      'claims': ['colorHunt', 'unknown'],
    }, october);
    expect(state.collected, 100000);
    expect(state.combos, 0);
    expect(state.finishedLevels, {2});
    expect(state.claimed, {V8Mission.colorHunt});
  });
}
