import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/game_engine.dart';

void main() {
  test('Yeni tahtalarda baslangic eslesmesi yok ve hamle var', () {
    for (var seed = 0; seed < 30; seed++) {
      final engine = MatchEngine(1, seed: seed);
      expect(engine.matches(), isEmpty, reason: 'Seed $seed');
      expect(engine.hasMove(), isTrue, reason: 'Seed $seed');
    }
  });

  test('Gecerli hamle en az uc sekeri eslestirir', () {
    final engine = MatchEngine(3, seed: 12);
    var found = false;
    for (var r = 0; r < gridSize && !found; r++) {
      for (var c = 0; c < gridSize && !found; c++) {
        final from = Cell(r, c);
        for (final to in [Cell(r + 1, c), Cell(r, c + 1)]) {
          if (engine.createsMatch(from, to)) {
            engine.swap(from, to);
            final result = engine.matches();
            expect(result.length, greaterThanOrEqualTo(3));
            engine.clear(result, 1);
            engine.collapse();
            for (final row in engine.board) {
              expect(row.every((item) => item != null), isTrue);
            }
            found = true;
            break;
          }
        }
      }
    }
    expect(found, isTrue);
  });

  test('Oyun ilerlemesi kaydedilip geri yuklenebilir', () {
    final engine = MatchEngine(8, seed: 7)
      ..moves = 17
      ..score = 2345
      ..collected = 9;
    final copy = MatchEngine.fromJson(engine.toJson());
    expect(copy.level, 8);
    expect(copy.moves, 17);
    expect(copy.score, 2345);
    expect(copy.collected, 9);
    expect(copy.board[3][4]?.id, engine.board[3][4]?.id);
  });
}
