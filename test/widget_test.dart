import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/game_engine.dart';

// Prevent flutter create from generating the default counter-app test.
void main() {
  test('Bolum hedefleri oynanabilir araliktadir', () {
    for (var level = 1; level <= 60; level++) {
      final config = LevelPlan(level);
      expect(config.totalMoves, greaterThanOrEqualTo(16));
      expect(config.target, greaterThan(0));
    }
  });
}
