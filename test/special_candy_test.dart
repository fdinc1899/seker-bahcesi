import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/game_engine.dart';

void main() {
  MatchEngine plainBoard() {
    final engine = MatchEngine(4, seed: 7);
    // Checker-like deterministic board without existing triples.
    engine.board = List.generate(gridSize, (r) => List.generate(gridSize, (c) =>
        Candy(r * gridSize + c, (r * 2 + c * 3) % candyTypes)));
    engine.nextId = 65;
    expect(engine.matches(), isEmpty);
    return engine;
  }

  test('4lu yatay eslesme cizgili seker verir', () {
    final engine = plainBoard();
    for (var c = 1; c <= 4; c++) {
      engine.board[3][c] = Candy(100 + c, 1);
    }
    final wave = engine.matchWave(preferred: const Cell(3, 2));
    expect(wave.spawns[const Cell(3, 2)], SpecialKind.horizontal);
    expect(wave.cells.length, greaterThanOrEqualTo(3));
    expect(wave.cells.contains(const Cell(3, 2)), isFalse);
    engine.clear(wave.cells, 1);
    engine.installSpecials(wave.spawns);
    expect(engine.board[3][2]?.special, SpecialKind.horizontal);
    engine.collapse();
    expect(engine.board.every((row) => row.every((c) => c != null)), isTrue);
  });

  test('4lu dikey eslesme dikey cizgili seker verir', () {
    final engine = plainBoard();
    for (var r = 1; r <= 4; r++) {
      engine.board[r][4] = Candy(100 + r, 2);
    }
    final wave = engine.matchWave(preferred: const Cell(2, 4));
    expect(wave.spawns[const Cell(2, 4)], SpecialKind.vertical);
  });

  test('5li eslesme renk bombasi olusturur', () {
    final engine = plainBoard();
    for (var c = 1; c <= 5; c++) {
      engine.board[2][c] = Candy(100 + c, 3);
    }
    final wave = engine.matchWave(preferred: const Cell(2, 3));
    expect(wave.spawns[const Cell(2, 3)], SpecialKind.colorBomb);
    engine.clear(wave.cells, 1);
    engine.installSpecials(wave.spawns);
    expect(engine.board[2][3]!.special, SpecialKind.colorBomb);
  });

  test('cizgili seker tetiklenirse tum satiri patlatir', () {
    final engine = plainBoard();
    engine.board[4][3] = const Candy(200, 1,
        special: SpecialKind.horizontal);
    final wave = engine.waveForCells({const Cell(4, 3)});
    for (var c = 0; c < gridSize; c++) {
      expect(wave.cells, contains(Cell(4, c)));
    }
  });

  test('renk bombasi swap komsusunun tum rengini patlatir', () {
    final engine = plainBoard();
    engine.board[4][3] = const Candy(200, 5,
        special: SpecialKind.colorBomb);
    engine.board[4][4] = const Candy(201, 2);
    engine.swap(const Cell(4, 3), const Cell(4, 4));
    final wave = engine.specialCombo(const Cell(4, 3), const Cell(4, 4));
    expect(wave, isNotNull);
    expect(wave!.cells, contains(const Cell(4, 3)));
    expect(wave.cells, contains(const Cell(4, 4)));
    expect(wave.cells, contains(const Cell(1, 0))); // type 2
  });

  test('birbirine dokunan iki cizgili seker combo baslatir', () {
    final engine = plainBoard();
    engine.board[2][2] = const Candy(200, 2,
        special: SpecialKind.horizontal);
    engine.board[2][3] = const Candy(201, 3,
        special: SpecialKind.vertical);
    engine.swap(const Cell(2, 2), const Cell(2, 3));
    final wave = engine.specialCombo(const Cell(2, 2), const Cell(2, 3));
    expect(wave, isNotNull);
    expect(wave!.cells.length, greaterThanOrEqualTo(15));
  });

  test('eski oyundan kayit ve yeni ozel sekerler birlikte yuklenir', () {
    final engine = plainBoard();
    final oldSave = engine.toJson();
    final restored = MatchEngine.fromJson(oldSave);
    expect(restored.board[0][0]?.special, SpecialKind.none);
    restored.board[1][1] = const Candy(300, 4,
        special: SpecialKind.colorBomb);
    final copy = MatchEngine.fromJson(restored.toJson());
    expect(copy.board[1][1]?.special, SpecialKind.colorBomb);
    expect(copy.moves, engine.moves);
    expect(copy.score, engine.score);
    expect(copy.level, engine.level);
  });
}
