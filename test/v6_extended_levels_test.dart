import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/game_engine.dart';

void main() {
  test('Original 60 levels retain their goals and move limits', () {
    expect(LevelPlan(1).target, 2390);
    expect(LevelPlan(1).totalMoves, 25);
    expect(LevelPlan(59).isCollection, isTrue);
    expect(LevelPlan(59).target, 48);
    expect(LevelPlan(60).target, 13600);
    expect(LevelPlan(60).totalMoves, 17);
  });

  test('New worlds have playable targets and moves', () {
    expect(LevelPlan(61).totalMoves, 24);
    expect(LevelPlan(61).target, 9000);
    expect(LevelPlan(62).isCollection, isTrue);
    expect(LevelPlan(62).target, 24);
    expect(LevelPlan(120).totalMoves, greaterThanOrEqualTo(22));
    expect(LevelPlan(120).target, lessThan(15000));
    for (final level in [61, 80, 81, 100, 101, 120]) {
      final engine = MatchEngine(level, seed: 19);
      expect(engine.matches(), isEmpty);
      expect(engine.hasMove(), isTrue);
    }
  });
}
