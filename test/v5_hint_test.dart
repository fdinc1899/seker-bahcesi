import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/game_engine.dart';

void main() {
  test('V5 suggested swap exists and does not change saved board', () {
    final game = MatchEngine(1, seed: 31);
    final before = jsonEncode(game.toJson());
    var found = false;
    for (var row = 0; row < gridSize && !found; row++) {
      for (var col = 0; col < gridSize && !found; col++) {
        final from = Cell(row, col);
        for (final to in [Cell(row, col + 1), Cell(row + 1, col)]) {
          if (game.inBounds(to) && game.createsMatch(from, to)) {
            found = true;
            break;
          }
        }
      }
    }
    expect(found, isTrue);
    expect(jsonEncode(game.toJson()), before);
  });
}
