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

class Candy {
  const Candy(this.id, this.type);
  final int id;
  final int type;

  Map<String, int> toJson() => {'id': id, 'type': type};
  factory Candy.fromJson(Map<String, dynamic> m) =>
      Candy((m['id'] as num).toInt(), (m['type'] as num).toInt());
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

  Candy _newCandy(int type) => Candy(nextId++, type);

  void newBoard() {
    for (var attempt = 0; attempt < 400; attempt++) {
      board = List.generate(gridSize, (_) => List<Candy?>.filled(gridSize, null));
      for (var r = 0; r < gridSize; r++) {
        for (var c = 0; c < gridSize; c++) {
          final allowed = List.generate(candyTypes, (i) => i);
          if (c >= 2 &&
              board[r][c - 1]?.type == board[r][c - 2]?.type) {
            allowed.remove(board[r][c - 1]!.type);
          }
          if (r >= 2 &&
              board[r - 1][c]?.type == board[r - 2][c]?.type) {
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

  Set<Cell> matches() {
    final result = <Cell>{};
    for (var row = 0; row < gridSize; row++) {
      var start = 0;
      while (start < gridSize) {
        final type = board[row][start]?.type;
        var end = start + 1;
        if (type != null) {
          while (end < gridSize && board[row][end]?.type == type) {
            end++;
          }
          if (end - start >= 3) {
            for (var c = start; c < end; c++) {
              result.add(Cell(row, c));
            }
          }
        }
        start = end;
      }
    }
    for (var col = 0; col < gridSize; col++) {
      var start = 0;
      while (start < gridSize) {
        final type = board[start][col]?.type;
        var end = start + 1;
        if (type != null) {
          while (end < gridSize && board[end][col]?.type == type) {
            end++;
          }
          if (end - start >= 3) {
            for (var r = start; r < end; r++) {
              result.add(Cell(r, col));
            }
          }
        }
        start = end;
      }
    }
    return result;
  }

  bool createsMatch(Cell a, Cell b) {
    if (!inBounds(a) || !inBounds(b) || !neighbors(a, b)) return false;
    swap(a, b);
    final found = matches().isNotEmpty;
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

  /// Called after the disappearance animation finishes.
  void clear(Set<Cell> cells, int chain) {
    for (final cell in cells) {
      final candy = board[cell.row][cell.col];
      if (candy == null) continue;
      if (plan.isCollection && candy.type == plan.focusType) collected++;
      board[cell.row][cell.col] = null;
    }
    score += cells.length * (100 + (chain - 1) * 55);
    if (cells.length >= 4) score += (cells.length - 3) * 60;
  }

  /// Gravity: retain candy IDs so AnimatedPositioned animates existing pieces.
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

  bool get won => plan.isCollection ? collected >= plan.target : score >= plan.target;
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
        'board': board
            .map((r) => r.map((c) => c?.toJson()).toList())
            .toList(),
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
