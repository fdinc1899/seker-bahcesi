import 'dart:math';

const int gridSize = 8;
const int candyTypes = 6;

class Cell {
  const Cell(this.row, this.col);
  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is Cell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

/// Kept optional in saves so V1/V2 Package 1 games load unchanged.
enum SpecialKind { none, horizontal, vertical, colorBomb }

class Candy {
  const Candy(this.id, this.type, {this.special = SpecialKind.none});
  final int id;
  final int type;
  final SpecialKind special;

  Map<String, int> toJson() => {
        'id': id,
        'type': type,
        if (special != SpecialKind.none) 'special': special.index,
      };

  factory Candy.fromJson(Map<String, dynamic> m) {
    final raw = (m['special'] as num?)?.toInt() ?? 0;
    return Candy(
      (m['id'] as num).toInt(),
      (m['type'] as num).toInt(),
      special: raw >= 0 && raw < SpecialKind.values.length
          ? SpecialKind.values[raw]
          : SpecialKind.none,
    );
  }
}

class LevelPlan {
  const LevelPlan(this.level);
  final int level;
  bool get isCollection => level % 3 == 2;
  int get focusType => (level ~/ 3 + 3) % candyTypes;
  int get target => isCollection ? 10 + (level ~/ 3) * 2 : 2200 + level * 190;
  int get totalMoves => max(16, 25 - (level - 1) ~/ 7);
  String get name {
    const names = [
      'Pamuk Şeker Tepesi', 'Çilek Ormanı', 'Vanilya Vadisi',
      'Renkli Şekerler', 'Bal Köpüğü Yolu', 'Limon Bahçesi',
      'Gökkuşağı Köyü', 'Çikolata Kanyonu', 'Jöle Adası',
      'Şeker Krallığı',
    ];
    return names[(level - 1) % names.length];
  }
}

class MatchGroup {
  const MatchGroup(this.cells, {required this.horizontal});
  final List<Cell> cells;
  final bool horizontal;
}

/// An atomic resolution: disappear these cells, then create any power candies.
/// Spawn cells are *not* cleared, unless swept up by another special effect.
class MatchWave {
  const MatchWave(this.cells, {this.spawns = const <Cell, SpecialKind>{}});
  final Set<Cell> cells;
  final Map<Cell, SpecialKind> spawns;
  bool get isEmpty => cells.isEmpty && spawns.isEmpty;
}

class MatchEngine {
  MatchEngine(int level, {int? seed})
      : level = level,
        random = Random(seed) {
    moves = plan.totalMoves;
    newBoard();
  }

  MatchEngine._restored(this.level, this.random);

  final int level;
  final Random random;
  LevelPlan get plan => LevelPlan(level);
  late List<List<Candy?>> board;
  late int moves;
  int score = 0;
  int collected = 0;
  int nextId = 0;

  Candy _newCandy(int type, {SpecialKind special = SpecialKind.none}) =>
      Candy(nextId++, type, special: special);

  void newBoard() {
    for (var attempt = 0; attempt < 400; attempt++) {
      board = List.generate(gridSize, (_) => List<Candy?>.filled(gridSize, null));
      for (var r = 0; r < gridSize; r++) {
        for (var c = 0; c < gridSize; c++) {
          final allowed = List.generate(candyTypes, (i) => i);
          if (c >= 2 && board[r][c - 1]?.type == board[r][c - 2]?.type) {
            allowed.remove(board[r][c - 1]!.type);
          }
          if (r >= 2 && board[r - 1][c]?.type == board[r - 2][c]?.type) {
            allowed.remove(board[r - 1][c]!.type);
          }
          board[r][c] = _newCandy(allowed[random.nextInt(allowed.length)]);
        }
      }
      if (hasMove()) return;
    }
    throw StateError('Oynanabilir tahta üretilemedi.');
  }

  bool inBounds(Cell a) =>
      a.row >= 0 && a.row < gridSize && a.col >= 0 && a.col < gridSize;

  bool neighbors(Cell a, Cell b) =>
      (a.row - b.row).abs() + (a.col - b.col).abs() == 1;

  void swap(Cell a, Cell b) {
    final temp = board[a.row][a.col];
    board[a.row][a.col] = board[b.row][b.col];
    board[b.row][b.col] = temp;
  }

  /// Longest contiguous, same-type horizontal and vertical groups.
  /// Color bombs never automatically count toward a regular color match.
  List<MatchGroup> matchGroups() {
    final groups = <MatchGroup>[];
    for (var row = 0; row < gridSize; row++) {
      var start = 0;
      while (start < gridSize) {
        final piece = board[row][start];
        var end = start + 1;
        if (piece != null && piece.special != SpecialKind.colorBomb) {
          while (end < gridSize) {
            final next = board[row][end];
            if (next == null || next.special == SpecialKind.colorBomb ||
                next.type != piece.type) break;
            end++;
          }
          if (end - start >= 3) {
            groups.add(MatchGroup(
              [for (var c = start; c < end; c++) Cell(row, c)],
              horizontal: true,
            ));
          }
        }
        start = end;
      }
    }
    for (var col = 0; col < gridSize; col++) {
      var start = 0;
      while (start < gridSize) {
        final piece = board[start][col];
        var end = start + 1;
        if (piece != null && piece.special != SpecialKind.colorBomb) {
          while (end < gridSize) {
            final next = board[end][col];
            if (next == null || next.special == SpecialKind.colorBomb ||
                next.type != piece.type) break;
            end++;
          }
          if (end - start >= 3) {
            groups.add(MatchGroup(
              [for (var r = start; r < end; r++) Cell(r, col)],
              horizontal: false,
            ));
          }
        }
        start = end;
      }
    }
    return groups;
  }

  Set<Cell> matches() => {
        for (final group in matchGroups()) ...group.cells,
      };

  /// Detect a swap-activated combo before deciding whether the move is legal.
  /// a and b are the *post-swap* positions.
  MatchWave? specialCombo(Cell a, Cell b) {
    if (!inBounds(a) || !inBounds(b) || !neighbors(a, b)) return null;
    final x = board[a.row][a.col];
    final y = board[b.row][b.col];
    if (x == null || y == null) return null;
    final bombX = x.special == SpecialKind.colorBomb;
    final bombY = y.special == SpecialKind.colorBomb;
    if (bombX || bombY) {
      if (bombX && bombY) {
        return MatchWave({for (var r = 0; r < gridSize; r++)
          for (var c = 0; c < gridSize; c++) Cell(r, c)});
      }
      final other = bombX ? y : x;
      final removed = <Cell>{a, b};
      for (var r = 0; r < gridSize; r++) {
        for (var c = 0; c < gridSize; c++) {
          if (board[r][c]?.type == other.type) {
            removed.add(Cell(r, c));
            // Bomb + stripe turns all of that color into line blasts.
            if (other.special == SpecialKind.horizontal) {
              for (var k = 0; k < gridSize; k++) removed.add(Cell(r, k));
            } else if (other.special == SpecialKind.vertical) {
              for (var k = 0; k < gridSize; k++) removed.add(Cell(k, c));
            }
          }
        }
      }
      return waveForCells(removed);
    }
    final stripedX = x.special == SpecialKind.horizontal ||
        x.special == SpecialKind.vertical;
    final stripedY = y.special == SpecialKind.horizontal ||
        y.special == SpecialKind.vertical;
    if (stripedX && stripedY) {
      final removed = <Cell>{a, b};
      for (final pos in [a, b]) {
        for (var i = 0; i < gridSize; i++) {
          removed.add(Cell(pos.row, i));
          removed.add(Cell(i, pos.col));
        }
      }
      return waveForCells(removed);
    }
    return null;
  }

  bool createsMatch(Cell a, Cell b) {
    if (!inBounds(a) || !inBounds(b) || !neighbors(a, b)) return false;
    swap(a, b);
    final found = matches().isNotEmpty || specialCombo(a, b) != null;
    swap(a, b);
    return found;
  }

  bool hasMove() {
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        final here = Cell(r, c);
        if (c + 1 < gridSize && createsMatch(here, Cell(r, c + 1))) {
          return true;
        }
        if (r + 1 < gridSize && createsMatch(here, Cell(r + 1, c))) {
          return true;
        }
      }
    }
    return false;
  }

  /// Create striped candies on lines of 4 and rainbow bombs on lines of 5+.
  /// Preference is the dragged destination, if part of the match.
  MatchWave matchWave({Cell? preferred}) {
    final groups = matchGroups();
    final removed = <Cell>{for (final group in groups) ...group.cells};
    final spawns = <Cell, SpecialKind>{};
    // Longer groups take priority when multiple matches cross.
    groups.sort((a, b) => b.cells.length.compareTo(a.cells.length));
    for (final group in groups) {
      if (group.cells.length < 4) continue;
      final type = group.cells.length >= 5
          ? SpecialKind.colorBomb
          : group.horizontal ? SpecialKind.horizontal : SpecialKind.vertical;
      final candidates = <Cell>[
        if (preferred != null && group.cells.contains(preferred)) preferred,
        group.cells[group.cells.length ~/ 2],
        ...group.cells,
      ];
      Cell? anchor;
      for (final spot in candidates) {
        if (spawns.containsKey(spot)) continue;
        if (board[spot.row][spot.col]?.special == SpecialKind.none) {
          anchor = spot;
          break;
        }
      }
      if (anchor != null) spawns[anchor] = type;
    }
    removed.removeAll(spawns.keys);
    final expanded = waveForCells(removed).cells;
    // Another power might destroy the newly spawned special this same turn.
    for (final spot in spawns.keys.toList()) {
      if (expanded.contains(spot)) spawns.remove(spot);
    }
    return MatchWave(expanded, spawns: spawns);
  }

  /// Expands line / rainbow special explosions, including chain reactions.
  MatchWave waveForCells(Set<Cell> initial) {
    final removed = <Cell>{};
    final queue = <Cell>[...initial];
    for (var i = 0; i < queue.length; i++) {
      final cell = queue[i];
      if (!inBounds(cell) || !removed.add(cell)) continue;
      final candy = board[cell.row][cell.col];
      if (candy == null) continue;
      if (candy.special == SpecialKind.horizontal) {
        for (var col = 0; col < gridSize; col++) {
          queue.add(Cell(cell.row, col));
        }
      } else if (candy.special == SpecialKind.vertical) {
        for (var row = 0; row < gridSize; row++) {
          queue.add(Cell(row, cell.col));
        }
      } else if (candy.special == SpecialKind.colorBomb) {
        for (var row = 0; row < gridSize; row++) {
          for (var col = 0; col < gridSize; col++) {
            if (board[row][col]?.type == candy.type) {
              queue.add(Cell(row, col));
            }
          }
        }
      }
    }
    return MatchWave(removed);
  }

  /// Called after the disappearance animation finishes.
  void clear(Set<Cell> cells, int chain) {
    var count = 0;
    for (final cell in cells) {
      if (!inBounds(cell)) continue;
      final candy = board[cell.row][cell.col];
      if (candy == null) continue;
      count++;
      if (plan.isCollection && candy.type == plan.focusType) collected++;
      board[cell.row][cell.col] = null;
    }
    score += count * (100 + (chain - 1) * 55);
    if (count >= 4) score += (count - 3) * 60;
  }

  /// Anchor positions remain occupied before gravity; IDs are unique.
  void installSpecials(Map<Cell, SpecialKind> creations) {
    for (final entry in creations.entries) {
      final cell = entry.key;
      final original = board[cell.row][cell.col];
      if (original != null) {
        board[cell.row][cell.col] =
            _newCandy(original.type, special: entry.value);
        score += entry.value == SpecialKind.colorBomb ? 400 : 160;
      }
    }
  }

  /// Gravity: preserve IDs to drive AnimatedPositioned movement.
  List<int> collapse() {
    final created = <int>[];
    for (var c = 0; c < gridSize; c++) {
      var bottom = gridSize - 1;
      for (var r = gridSize - 1; r >= 0; r--) {
        final piece = board[r][c];
        if (piece != null) {
          board[bottom][c] = piece;
          if (bottom != r) board[r][c] = null;
          bottom--;
        }
      }
      for (var r = bottom; r >= 0; r--) {
        final piece = _newCandy(random.nextInt(candyTypes));
        board[r][c] = piece;
        created.add(piece.id);
      }
    }
    return created;
  }

  bool get won =>
      plan.isCollection ? collected >= plan.target : score >= plan.target;
  double get progress =>
      ((plan.isCollection ? collected : score) / plan.target).clamp(0.0, 1.0);

  int get stars {
    if (!won) return 0;
    final fraction = moves / plan.totalMoves;
    return fraction >= .42 ? 3 : (fraction >= .15 ? 2 : 1);
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'moves': moves,
        'score': score,
        'collected': collected,
        'nextId': nextId,
        'board': board.map((r) => r.map((c) => c?.toJson()).toList()).toList(),
      };

  factory MatchEngine.fromJson(Map<String, dynamic> data) {
    final level = (data['level'] as num).toInt();
    final engine = MatchEngine._restored(level, Random());
    engine.moves = (data['moves'] as num).toInt();
    engine.score = (data['score'] as num).toInt();
    engine.collected = (data['collected'] as num).toInt();
    engine.nextId = (data['nextId'] as num).toInt();
    final rows = data['board'] as List<dynamic>;
    if (rows.length != gridSize) throw const FormatException('Invalid rows');
    engine.board = rows.map((row) {
      final cols = row as List<dynamic>;
      if (cols.length != gridSize) throw const FormatException('Invalid cols');
      return cols.map((item) => item == null
          ? null
          : Candy.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    }).toList();
    return engine;
  }
}
