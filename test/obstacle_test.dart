import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/game_engine.dart';

void main() {
  test('engel turleri bolum ilerledikce acilir', () {
    final early = MatchEngine(1, seed: 3);
    final ice = MatchEngine(3, seed: 3);
    final chocolate = MatchEngine(5, seed: 3);
    final locks = MatchEngine(7, seed: 3);
    expect(early.remainingObstacles, 0);
    expect(ice.countObstacle(ObstacleKind.ice), greaterThan(0));
    expect(ice.countObstacle(ObstacleKind.chocolate), 0);
    expect(chocolate.countObstacle(ObstacleKind.chocolate), greaterThan(0));
    expect(locks.countObstacle(ObstacleKind.lock), greaterThan(0));
    expect(locks.hasMove(), isTrue);
  });

  test('buz iki kez vurulunca kirilir', () {
    final game = MatchEngine(3, seed: 9);
    const at = Cell(2, 3);
    game.obstacles[at.row][at.col] = 2;
    expect(game.damageObstacles({at}), 1);
    expect(game.obstacleCode(at), 1);
    expect(game.damageObstacles({at}), 1);
    expect(game.obstacleCode(at), 0);
  });

  test('kilit ve cikolata suruklemeyi engeller', () {
    final game = MatchEngine(1, seed: 2);
    const a = Cell(3, 3);
    const b = Cell(3, 4);
    game.obstacles[a.row][a.col] = 4;
    expect(game.canSwap(a, b), isFalse);
    expect(game.createsMatch(a, b), isFalse);
    game.obstacles[a.row][a.col] = 3;
    expect(game.canSwap(a, b), isFalse);
    game.obstacles[a.row][a.col] = 0;
    expect(game.canSwap(a, b), isTrue);
  });

  test('kesisen komsu eslesmeler kilit ve cikolatayi kirar', () {
    final game = MatchEngine(1, seed: 2);
    const chocolate = Cell(3, 3);
    const lock = Cell(4, 2);
    game.obstacles[chocolate.row][chocolate.col] = 3;
    game.obstacles[lock.row][lock.col] = 4;
    expect(game.damageObstacles({const Cell(3, 2)}), 2);
    expect(game.obstacleCode(chocolate), 0);
    expect(game.obstacleCode(lock), 0);
  });

  test('cikolata komsu karelere yayilir ama altidan fazla olmaz', () {
    final game = MatchEngine(1, seed: 1);
    game.obstacles[3][3] = 3;
    expect(game.spreadChocolate(), isTrue);
    expect(game.countObstacle(ObstacleKind.chocolate), 2);
    for (var i = 0; i < 12; i++) {
      game.spreadChocolate();
    }
    expect(game.countObstacle(ObstacleKind.chocolate), 6);
  });

  test('eski kayitlar engel olmadan acilir ve yeni katmanlar saklanir', () {
    final old = MatchEngine(13, seed: 4).toJson();
    old.remove('obstacles');
    final migrated = MatchEngine.fromJson(old);
    expect(migrated.remainingObstacles, 0);
    migrated.obstacles[1][1] = 2;
    migrated.obstacles[2][2] = 4;
    final restored = MatchEngine.fromJson(migrated.toJson());
    expect(restored.obstacleCode(const Cell(1, 1)), 2);
    expect(restored.obstacleCode(const Cell(2, 2)), 4);
    expect(restored.moves, migrated.moves);
    expect(restored.score, migrated.score);
  });

  test('karistirma mevcut engel katmanlarini silmez', () {
    final game = MatchEngine(13, seed: 4);
    final before = game.obstacles.map((row) => row.toList()).toList();
    game.newBoard();
    expect(game.obstacles, before);
    expect(game.hasMove(), isTrue);
  });
}
