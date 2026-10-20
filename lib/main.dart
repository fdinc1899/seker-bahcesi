import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'candy_art.dart';
import 'game_engine.dart';
import 'game_audio.dart';
import 'v5_fx.dart';
import 'v6_progress.dart';
import 'v7_events.dart';
import 'v8_season.dart';
import 'v9_rewards.dart';
import 'v9_wheel.dart';
import 'level_result.dart';
import 'reward_rules.dart';
import 'daily_rewards.dart';
import 'v12_backup.dart';
import 'v12_map_path.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SugarGarden());
}

enum ViewPage { home, map, play }
enum PowerMode { none, hammer, line }

class SugarGarden extends StatefulWidget {
  const SugarGarden({super.key});

  @override
  State<SugarGarden> createState() => _SugarGardenState();
}

class _SugarGardenState extends State<SugarGarden>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final GameAudio _audio = GameAudio();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  SharedPreferences? _storage;
  bool _loading = true;
  bool _sound = true;
  ViewPage _page = ViewPage.home;
  MatchEngine? _game;
  int _unlocked = 1;
  final Map<int, int> _stars = {};
  int _hammers = 3;
  int _lineBlasts = 2;
  int _shuffles = 3;
  bool _busy = false;
  bool? _result;
  bool _threeStarPrize = false;
  DailyProgress _daily = DailyProgress.fresh(DateTime.now());
  V6Progress _v6 = V6Progress();
  V7Progress _v7 = V7Progress(today: DateTime.now());
  V8SeasonProgress _v8 = V8SeasonProgress(today: DateTime.now());
  V9RewardsProgress _v9 = V9RewardsProgress(today: DateTime.now());
  PowerMode _power = PowerMode.none;
  Cell? _selected;
  Cell? _dragStart;
  Offset _dragDistance = Offset.zero;
  String _message = 'Üç veya daha fazla şekeri eşleştir!';
  String _comboBanner = '';
  Set<int> _vanishing = {};
  Set<int> _newborn = {};
  List<Offset> _burstPositions = [];
  List<Color> _burstColors = [];
  List<Cell> _hintCells = [];
  int _burstPoints = 0;
  int _comboCount = 0;
  late final AnimationController _hintAnimation;
  late final AnimationController _winAnimation;
  late final AnimationController _burstAnimation;
  double _boardCell = 40;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _burstAnimation = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 950));
    _hintAnimation = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 840));
    _winAnimation = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2900));
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _audio.pauseMusic();
      _save();
    } else if (state == AppLifecycleState.resumed) {
      _audio.resumeMusic();
      _daily.advance(DateTime.now());
      setState(() {
        _v7.advance(DateTime.now());
        _v8.advance(DateTime.now());
        _v9.advance(DateTime.now());
      });
      _save();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _burstAnimation.dispose();
    _hintAnimation.dispose();
    _winAnimation.dispose();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _storage = prefs;
    try {
      _unlocked = prefs.getInt('unlocked') ?? 1;
      _sound = prefs.getBool('sound') ?? true;
      _hammers = prefs.getInt('hammers') ?? 3;
      _lineBlasts = prefs.getInt('lineBlasts') ?? 2;
      _shuffles = prefs.getInt('shuffles') ?? 3;
      final savedV6 = prefs.getString('v6Progress');
      if (savedV6 != null) {
        try {
          _v6 = V6Progress.fromJson(
            Map<String, dynamic>.from(jsonDecode(savedV6) as Map));
        } catch (_) {
          _v6 = V6Progress();
        }
      }
      final v7Data = prefs.getString('v7Progress');
      if (v7Data != null) {
        try {
          _v7 = V7Progress.fromJson(
              Map<String, dynamic>.from(jsonDecode(v7Data) as Map),
              DateTime.now());
        } catch (_) {
          _v7 = V7Progress(today: DateTime.now());
        }
      }
      final v8Data = prefs.getString('v8Season');
      if (v8Data != null) {
        try {
          _v8 = V8SeasonProgress.fromJson(
              Map<String, dynamic>.from(jsonDecode(v8Data) as Map),
              DateTime.now());
        } catch (_) {
          _v8 = V8SeasonProgress(today: DateTime.now());
        }
      }
      final v9Data = prefs.getString('v9Rewards');
      if (v9Data != null) {
        try {
          _v9 = V9RewardsProgress.fromJson(
              Map<String, dynamic>.from(jsonDecode(v9Data) as Map),
              DateTime.now());
        } catch (_) {
          _v9 = V9RewardsProgress(today: DateTime.now());
        }
      }
      final progress = prefs.getString('stars');
      if (progress != null) {
        (jsonDecode(progress) as Map<String, dynamic>).forEach((key, value) {
          _stars[int.parse(key)] = (value as num).toInt();
        });
      }
      _unlocked = v6MigrateUnlocked(_unlocked, _stars);
      final dailyData = prefs.getString('dailyProgressV2');
      if (dailyData != null) {
        _daily = DailyProgress.fromJson(
          Map<String, dynamic>.from(jsonDecode(dailyData) as Map), DateTime.now());
      } else {
        _daily = DailyProgress.fresh(DateTime.now());
      }
      final saved = prefs.getString('session');
      if (saved != null) {
        final session = MatchEngine.fromJson(
            Map<String, dynamic>.from(jsonDecode(saved) as Map));
        if (session.moves > 0 && !session.won && session.matches().isEmpty) {
          _game = session;
        }
      }
    } catch (_) {
      // A damaged save should not prevent the player from starting a new game.
      _game = null;
    }
    await _audio.initialize(enabled: _sound);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = _storage;
    if (prefs == null) return;
    await prefs.setInt('unlocked', _unlocked);
    await prefs.setString('stars',
        jsonEncode(_stars.map((key, value) => MapEntry('$key', value))));
    await prefs.setBool('sound', _sound);
    await prefs.setInt('hammers', _hammers);
    await prefs.setInt('lineBlasts', _lineBlasts);
    await prefs.setInt('shuffles', _shuffles);
    await prefs.setString('dailyProgressV2', jsonEncode(_daily.toJson()));
    await prefs.setString('v6Progress', jsonEncode(_v6.toJson()));
    await prefs.setString('v7Progress', jsonEncode(_v7.toJson()));
    await prefs.setString('v8Season', jsonEncode(_v8.toJson()));
    await prefs.setString('v9Rewards', jsonEncode(_v9.toJson()));
    final g = _game;
    if (g != null && g.moves > 0 && !g.won) {
      await prefs.setString('session', jsonEncode(g.toJson()));
    } else {
      await prefs.remove('session');
    }
  }

  void _toggleSound() {
    setState(() => _sound = !_sound);
    _audio.setEnabled(_sound);
    _save();
  }

  void _fx({bool strong = false}) {
    if (!_sound) return;
    _audio.play(strong ? CandySound.swipe : CandySound.tap);
    if (strong) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  int _continueLevel() {
    final current = _game;
    if (current != null && !current.won && current.moves > 0) {
      return current.level;
    }
    return _unlocked;
  }

  void _openGame(int level) {
    if (level > _unlocked || level < 1 || level > v6LevelCount) return;
    setState(() {
      if (_game == null || _game!.level != level ||
          _game!.won || _game!.moves <= 0) {
        _game = MatchEngine(level);
      }
      _page = ViewPage.play;
      _result = null;
      _threeStarPrize = false;
      _busy = false;
      _selected = null;
      _power = PowerMode.none;
      _message = 'Şekerleri sürükle ve eşleştir!';
      _comboBanner = '';
      _comboCount = 0;
      _burstPoints = 0;
      _hintCells = [];
      _hintAnimation.stop();
      _winAnimation.reset();
      _vanishing = {};
      _newborn = {};
    });
    _fx();
    _save();
  }

  void _leaveGame() {
    if (_busy) return;
    setState(() {
      _page = ViewPage.home;
      _hintCells = [];
      _hintAnimation.stop();
      _result = null;
      _threeStarPrize = false;
      _power = PowerMode.none;
    });
    _save();
  }

  Future<void> _trySwap(Cell a, Cell b) async {
    final g = _game;
    if (g == null || _busy || _result != null ||
        !g.inBounds(a) || !g.inBounds(b) || !g.neighbors(a, b)) return;
    if (!g.canSwap(a, b)) {
      setState(() => _message = 'Önce çikolata veya kilidi kır!');
      return;
    }
    setState(() {
      _busy = true;
      _selected = null;
      _hintCells = [];
      _hintAnimation.stop();
      _comboCount = 0;
      _message = '';
      g.swap(a, b);
    });
    await Future<void>.delayed(const Duration(milliseconds: 315));
    if (!mounted) return;
    final combo = g.specialCombo(a, b);
    if (g.matches().isEmpty && combo == null) {
      setState(() {
        g.swap(a, b);
        _message = 'Bu hamle eşleşme oluşturmuyor.';
      });
      await Future<void>.delayed(const Duration(milliseconds: 315));
      if (mounted) setState(() => _busy = false);
      return;
    }
    g.moves--;
    _daily.registerMatch(DateTime.now());
    _fx(strong: true);
    await _resolve(firstWave: combo, preferred: b);
  }

  Future<void> _resolve({MatchWave? firstWave, Cell? preferred}) async {
    final g = _game;
    if (g == null) return;
    var chain = 1;
    var damagedChocolate = false;
    var wave = firstWave ?? g.matchWave(preferred: preferred);
    while (!wave.isEmpty && chain <= 25) {
      final matched = wave.cells;
      _burstPositions = matched
          .map((cell) => Offset(
              (cell.col + .5) * _boardCell + 5,
              (cell.row + .5) * _boardCell + 5))
          .toList();
      final matchedCandyTypes = matched.map((cell) =>
          g.board[cell.row][cell.col]?.type).whereType<int>().toList();
      _burstColors = matched.map((cell) {
        final candy = g.board[cell.row][cell.col];
        return candyPalette[candy?.type ?? 0];
      }).toList();
      setState(() {
        _comboCount = chain;
        _burstPoints = matched.length * (100 + (chain - 1) * 55) +
            math.max(0, matched.length - 3) * 60;
        _vanishing = matched
            .map((cell) => g.board[cell.row][cell.col]?.id)
            .whereType<int>()
            .toSet();
        _message = chain > 1 ? 'SÜPER KOMBO x$chain!' :
            wave.spawns.values.contains(SpecialKind.colorBomb)
                ? 'RENK BOMBASI!'
                : wave.spawns.isNotEmpty ? 'ÖZEL ŞEKER!'
                : matched.length >= 10 ? 'MEGA PATLAMA!'
                : matched.length >= 5 ? 'MUHTEŞEM!' : 'HARİKA!';
        _comboBanner = _message;
      });
      _audio.play(chain > 1 ? CandySound.combo
          : wave.spawns.isNotEmpty || matched.length >= 7
              ? CandySound.special : CandySound.pop);
      _burstAnimation.forward(from: 0);
      await Future<void>.delayed(const Duration(milliseconds: 390));
      if (!mounted) return;
      final chocolateBefore = g.countObstacle(ObstacleKind.chocolate);
      final damaged = g.damageObstacles(matched);
      if (g.countObstacle(ObstacleKind.chocolate) < chocolateBefore) {
        damagedChocolate = true;
      }
      g.clear(matched, chain);
      _v8.recordWave(matchedCandyTypes, chain, DateTime.now());
      _v9.recordWave(matchedCandyTypes);
      if (damaged > 0 && chain == 1) {
        _message = 'ENGEL KIRILDI!';
      }
      if (wave.spawns.isNotEmpty) {
        _daily.registerSpecial(DateTime.now(), wave.spawns.length);
      }
      g.installSpecials(wave.spawns);
      final ids = g.collapse();
      setState(() {
        _vanishing = {};
        _newborn = ids.toSet();
      });
      await Future<void>.delayed(const Duration(milliseconds: 485));
      if (!mounted) return;
      setState(() {
        _newborn = {};
        _comboBanner = '';
      });
      wave = g.matchWave();
      chain++;
    }
    if (g.moves > 0 && !g.won && !damagedChocolate) {
      g.spreadChocolate();
    }
    if (!g.hasMove()) {
      g.newBoard();
      setState(() => _message = 'Yeni şekerler karıştırıldı!');
    }
    if (g.won) {
      _daily.registerWin(DateTime.now());
      _v7.recordWin(g.level, DateTime.now());
      _v8.recordWin(g.level, DateTime.now());
      // The existing best-stars save key prevents repeat reward farming.
      final previousBest = _stars[g.level] ?? 0;
      final earned = g.stars;
      final prize = prizeForLevel(previousBest: previousBest, stars: earned);
      final earnedCoins = v6CoinsForWin(
          previousBest: previousBest, stars: earned);
      _v6.coins += earnedCoins;
      _unlocked = math.max(_unlocked, math.min(v6LevelCount, g.level + 1));
      _stars[g.level] = math.max(previousBest, earned);
      if (prize.awarded) _shuffles += prize.bonusShuffles;
      setState(() {
        _threeStarPrize = prize.awarded;
        _result = true;
        _message = 'BÖLÜM TAMAMLANDI!';
      });
      _audio.play(CandySound.win);
      _winAnimation.forward(from: 0);
      _fx(strong: true);
      if (earnedCoins > 0) {
        final navContext = _navigatorKey.currentContext;
        if (navContext != null) {
          ScaffoldMessenger.of(navContext).showSnackBar(SnackBar(
            content: Text('Bölüm ödülü: +$earnedCoins 🍬 şeker parası!'),
            duration: const Duration(seconds: 3),
          ));
        }
      }
    } else if (g.moves <= 0) {
      setState(() {
        _result = false;
        _message = 'Hamlelerin tükendi!';
      });
      _audio.play(CandySound.lose);
    }
    if (mounted) setState(() => _busy = false);
    await _save();
  }

  Future<void> _useSpecial(Cell cell) async {
    final g = _game;
    if (g == null || _busy || _result != null || g.moves == 0) return;
    final mode = _power;
    if (mode == PowerMode.none) return;
    if (mode == PowerMode.hammer && _hammers <= 0) return;
    if (mode == PowerMode.line && _lineBlasts <= 0) return;
    final cells = mode == PowerMode.hammer
        ? <Cell>{cell}
        : {for (var col = 0; col < gridSize; col++) Cell(cell.row, col)};
    setState(() {
      if (mode == PowerMode.hammer) {
        _hammers--;
      } else {
        _lineBlasts--;
      }
      _power = PowerMode.none;
      _selected = null;
      _busy = true;
      _hintCells = [];
      _hintAnimation.stop();
      g.moves--;
    });
    _fx(strong: true);
    await _resolve(firstWave: g.waveForCells(cells));
  }

  void _shuffle() {
    final g = _game;
    if (g == null || _busy || _result != null || _shuffles <= 0) return;
    setState(() {
      _shuffles--;
      _hintCells = [];
      _hintAnimation.stop();
      _power = PowerMode.none;
      _selected = null;
      g.newBoard();
      _message = 'Şekerler yeniden karıştı!';
    });
    _audio.play(CandySound.special);
    _save();
  }

  // V5: an on-demand suggestion. createsMatch restores the original board
  // after simulating the swap, so this never spends moves or changes a save.
  void _showHint() {
    final g = _game;
    if (g == null || _busy || _result != null) return;
    List<Cell>? suggestion;
    for (var r = 0; r < gridSize && suggestion == null; r++) {
      for (var c = 0; c < gridSize && suggestion == null; c++) {
        final first = Cell(r, c);
        for (final second in <Cell>[Cell(r, c + 1), Cell(r + 1, c)]) {
          if (g.inBounds(second) && g.createsMatch(first, second)) {
            suggestion = [first, second];
            break;
          }
        }
      }
    }
    if (suggestion == null) {
      setState(() => _message = 'Hamle bulunamadı, karıştırmayı dene!');
      return;
    }
    setState(() {
      _hintCells = suggestion!;
      _selected = null;
      _message = 'İPUCU: Parlayan iki şekeri yer değiştir!';
    });
    _hintAnimation.repeat(reverse: true);
    _fx();
  }

  Cell? _touchCell(Offset point) {
    final col = ((point.dx - 5) / _boardCell).floor();
    final row = ((point.dy - 5) / _boardCell).floor();
    final cell = Cell(row, col);
    return _game?.inBounds(cell) == true ? cell : null;
  }

  void _tapBoard(Offset position) {
    if (_busy || _result != null) return;
    final cell = _touchCell(position);
    if (cell == null) return;
    if (_power != PowerMode.none) {
      _useSpecial(cell);
      return;
    }
    final previous = _selected;
    if (previous != null && previous != cell &&
        _game!.neighbors(previous, cell)) {
      _trySwap(previous, cell);
    } else {
      setState(() => _selected = cell);
      _fx();
    }
  }

  void _finishDrag() {
    if (_busy || _result != null) return;
    final from = _dragStart;
    if (from == null || _dragDistance.distance < 16) return;
    if (_power != PowerMode.none) {
      _useSpecial(from);
      return;
    }
    final isHorizontal = _dragDistance.dx.abs() > _dragDistance.dy.abs();
    final dest = isHorizontal
        ? Cell(from.row, from.col + (_dragDistance.dx > 0 ? 1 : -1))
        : Cell(from.row + (_dragDistance.dy > 0 ? 1 : -1), from.col);
    _trySwap(from, dest);
  }

  void _receiveGift(DailyGift gift) {
    _hammers += gift.hammers;
    _lineBlasts += gift.lines;
    _shuffles += gift.shuffles;
    _audio.play(CandySound.win);
    _save();
  }

  void _openDailyRewards() {
    _daily.advance(DateTime.now());
    _fx();
    _save();
    final navContext = _navigatorKey.currentContext;
    if (navContext == null) return;
    showDialog<void>(
      context: navContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refreshDialog) {
          final canClaim = _daily.canClaim(DateTime.now());
          return AlertDialog(
            key: const ValueKey('daily-rewards-dialog'),
            backgroundColor: const Color(0xFFFFF8F4),
            elevation: 12,
            shadowColor: const Color(0xAA81326C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: const BorderSide(color: Color(0xFFFFD58E), width: 3)),
            titlePadding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
            title: Container(
              key: const ValueKey('v15-daily-header'),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFFFE65B1), Color(0xFFE82E9E), Color(0xFFA936BC)]),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFFFEAAF), width: 3),
                boxShadow: const [BoxShadow(color: Color(0x66B13793),
                  blurRadius: 8, offset: Offset(0, 4))]),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard_rounded, size: 25, color: Colors.white),
                  SizedBox(width: 7),
                  Flexible(child: Text('GÜNLÜK HEDİYELER',
                    textAlign: TextAlign.center, maxLines: 2,
                    style: TextStyle(color: Colors.white,
                      fontSize: 19, fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Color(0x88672082),
                        blurRadius: 3, offset: Offset(0, 2))]))),
                ]),
            ),
            content: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Hediye serisi: ${_daily.streak} gün',
                  style: const TextStyle(fontWeight: FontWeight.w800,
                    color: Color(0xFF8D489B))),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const ValueKey('daily-claim'),
                  onPressed: canClaim ? () {
                    final reward = _daily.claim(DateTime.now());
                    if (reward == null) return;
                    setState(() => _receiveGift(reward));
                    refreshDialog(() {});
                    ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                      content: Text('Günlük hediye: ${reward.description}'),
                      duration: const Duration(seconds: 2),
                    ));
                  } : null,
                  icon: const Icon(Icons.redeem_rounded),
                  label: Text(canClaim ? 'BUGÜNKÜ HEDİYENİ AL' : 'BUGÜN ALINDI ✓',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD62F94),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(children: [
                  Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFFFFA62D), size: 21),
                  SizedBox(width: 7),
                  Expanded(child: Text('GÜNLÜK GÖREVLER', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900,
                    color: Color(0xFF652174)))),
                ]),
                const SizedBox(height: 5),
                for (var task = 0; task < 3; task++) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 9),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFFFF2E5)]),
                      borderRadius: BorderRadius.circular(19),
                      boxShadow: const [BoxShadow(
                        color: Color(0x40C85A99), blurRadius: 10,
                        offset: Offset(0, 4))],
                      border: Border.all(color: const Color(0xFFFFCA9D), width: 1.5),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Image.asset(switch (task) {
                            0 => 'assets/images/v14_hearts.webp',
                            1 => 'assets/images/v14_bomb.webp',
                            _ => 'assets/images/v14_crown.webp',
                          }, width: 42, height: 42),
                          const SizedBox(width: 6),
                          Expanded(child: Text(_daily.title(task),
                            style: const TextStyle(fontWeight: FontWeight.w800,
                              color: Color(0xFF76338B)))),
                          Text('${_daily.progress(task).clamp(0, _daily.goal(task))}/${_daily.goal(task)}',
                            style: const TextStyle(color: Color(0xFFB92381),
                              fontWeight: FontWeight.w900, fontSize: 14)),
                        ]),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: (_daily.progress(task) / _daily.goal(task))
                            .clamp(0.0, 1.0).toDouble(),
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF3E3F5),
                          color: const Color(0xFFFF77AE)),
                        const SizedBox(height: 5),
                        Align(alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            key: ValueKey('daily-mission-$task'),
                            onPressed: _daily.canCollectMission(task) ? () {
                              final reward = _daily.collectMission(task);
                              if (reward == null) return;
                              setState(() => _receiveGift(reward));
                              refreshDialog(() {});
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('Ödül: ${reward.description}')));
                            } : null,
                            icon: Icon(_daily.rewarded.contains(task)
                              ? Icons.check_circle_rounded : Icons.redeem_rounded, size: 18),
                            label: Text(_daily.rewarded.contains(task)
                              ? 'ALINDI ✓' : 'ÖDÜLÜ AL',
                              style: const TextStyle(fontWeight: FontWeight.w900,
                                fontSize: 12)),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFFBD41),
                              foregroundColor: const Color(0xFF6C2366),
                              disabledBackgroundColor: const Color(0xFFF1E5EF),
                              disabledForegroundColor: const Color(0xFF89708F),
                              minimumSize: const Size(132, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                                side: BorderSide(color: _daily.canCollectMission(task)
                                  ? const Color(0xFFFF8D34)
                                  : const Color(0xFFD9C9DD), width: 1.5)),
                            ),
                          )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const Text('Görevler her gece sıfırlanır. Ödüller bu cihazda saklanır.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF976CA0))),
              ],
            )),
            actions: [TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('KAPAT'),
            )],
          );
        },
      ),
    );
  }

  void _buyBooster(V6Booster booster, VoidCallback refresh) {
    if (!_v6.purchase(booster)) return;
    setState(() {
      switch (booster) {
        case V6Booster.hammer:
          _hammers++;
          break;
        case V6Booster.line:
          _lineBlasts++;
          break;
        case V6Booster.shuffle:
          _shuffles++;
          break;
      }
    });
    refresh();
    _fx();
    _save();
  }

  void _openShop() {
    final navContext = _navigatorKey.currentContext;
    if (navContext == null) return;
    _fx();
    showModalBottomSheet<void>(
      context: navContext,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF4EE),
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        side: BorderSide(color: Color(0xFFFFD8A1), width: 3)),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refresh) => SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 25),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/images/v15_shop_banner.png',
              height: 94, fit: BoxFit.contain,
              semanticLabel: 'ŞEKER DÜKKÂNI'),
            const SizedBox(height: 6),
            Text('🍬 ${_v6.coins} şeker paran var',
              key: const ValueKey('v6-coin-balance'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: Color(0xFF9A428A))),
            const SizedBox(height: 12),
            for (final booster in V6Booster.values)
              Padding(padding: const EdgeInsets.symmetric(vertical: 4),
                child: Card(
                  color: const Color(0xFFFFFEFA),
                  elevation: 5,
                  shadowColor: const Color(0x80B55A98),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: const BorderSide(color: Color(0xFFFFC981), width: 1.8)),
                  child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(switch (booster) {
                      V6Booster.hammer => 'assets/images/v14_hammer.webp',
                      V6Booster.line => 'assets/images/v14_line.webp',
                      V6Booster.shuffle => 'assets/images/v14_shuffle.webp',
                    }, width: 54, height: 54, fit: BoxFit.contain)),
                  title: Text(switch (booster) {
                    V6Booster.hammer => 'Çekiç',
                    V6Booster.line => 'Satır patlatma',
                    V6Booster.shuffle => 'Karıştırma',
                  }, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${v6BoosterPrice(booster)} 🍬'),
                  trailing: FilledButton(
                    key: ValueKey('v6-buy-${booster.name}'),
                    onPressed: _v6.canAfford(booster)
                        ? () => _buyBooster(booster, () => refresh(() {}))
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF49C328),
                      foregroundColor: Colors.white),
                    child: const Text('AL'),
                  ),
                ))),
            const SizedBox(height: 8),
            const Text('Şeker paraları bölümleri geçerek kazanılır. '
              'Gerçek para veya reklam yok.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF795D86))),
          ]),
        )),
      ),
    );
  }

  void _claimWorldChest(int endLevel) {
    final reward = _v6.claimChest(endLevel, _stars);
    if (reward == null) return;
    setState(() {
      _hammers += reward.hammers;
      _shuffles += reward.shuffles;
    });
    _audio.play(CandySound.win);
    _save();
    final navContext = _navigatorKey.currentContext;
    if (navContext != null) {
      ScaffoldMessenger.of(navContext).showSnackBar(SnackBar(
        content: Text('Dünya sandığı açıldı! +${reward.coins} 🍬, '
          '+${reward.hammers} çekiç, +${reward.shuffles} karıştırma'),
        duration: const Duration(seconds: 4),
      ));
    }
  }

  // V7: Offline weekly milestones and collectible achievement badges.
  // Rewards credit the existing V6 economy; never modify older save formats.
  void _grantV7Prize(V7Reward prize) {
    _v6.coins += prize.coins;
    _hammers += prize.hammers;
    _shuffles += prize.shuffles;
  }

  void _claimV7Week(int index, StateSetter refresh) {
    final prize = _v7.claimWeekly(index, DateTime.now());
    if (prize == null) return;
    setState(() => _grantV7Prize(prize));
    refresh(() {});
    _audio.play(CandySound.win);
    _save();
  }

  void _claimV7Badge(V7Badge badge, StateSetter refresh) {
    final prize = _v7.claimBadge(badge, _stars);
    if (prize == null) return;
    setState(() => _grantV7Prize(prize));
    refresh(() {});
    _audio.play(CandySound.win);
    _save();
  }

  void _openEventCenter() {
    final navContext = _navigatorKey.currentContext;
    if (navContext == null) return;
    setState(() {
      _v7.advance(DateTime.now());
      _v8.advance(DateTime.now());
      _v9.advance(DateTime.now());
    });
    _fx();
    showModalBottomSheet<void>(
      context: navContext,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF4FD),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refresh) => SafeArea(child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .90,
          child: Column(children: [
            const SizedBox(height: 16),
            Container(
              key: const ValueKey('v7-event-center'),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFFFF66B6), Color(0xFFD927A6), Color(0xFF852BC5)]),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: const Color(0xFFFFE3A8), width: 2.4),
                boxShadow: const [BoxShadow(color: Color(0x665C235D),
                  blurRadius: 9, offset: Offset(0, 5))],
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_rounded, color: Color(0xFFFFE19B), size: 29),
                  SizedBox(width: 8),
                  Flexible(child: Text('ETKİNLİK MERKEZİ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [Shadow(color: Color(0x88501A77),
                        blurRadius: 3, offset: Offset(0, 2))]))),
                ]),
            ),
            const SizedBox(height: 5),
            Text('🍬 ${_v6.coins}  •  Haftanın başlangıcı: ${_v7.week}',
              style: const TextStyle(fontWeight: FontWeight.w700,
                  color: Color(0xFF8B5694))),
            const Divider(height: 22),
            Expanded(child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
              children: [
                _v9DailyCard(refresh),
                const SizedBox(height: 14),
                _v9CollectionCard(refresh),
                const SizedBox(height: 18),
                _v8SeasonCard(refresh),
                const SizedBox(height: 18),
                const Text('HAFTALIK ŞEKER YARIŞI',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900,
                      color: Color(0xFF8337A0))),
                const SizedBox(height: 3),
                Text('Bu hafta ${_v7.completedThisWeek.length} farklı bölüm tamamladın. '
                  'Her Pazartesi yeni hedefler başlar.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF754B80))),
                const SizedBox(height: 8),
                for (var index = 0; index < v7WeeklyTiers.length; index++)
                  _v7WeeklyTile(index, refresh),
                const SizedBox(height: 20),
                const Text('BAŞARIM KOLEKSİYONU',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900,
                      color: Color(0xFF8337A0))),
                const SizedBox(height: 4),
                const Text('Kazandığın yıldızlar ve bölümler kalıcı olarak sayılır.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF754B80))),
                const SizedBox(height: 6),
                for (final badge in v7Badges)
                  _v7BadgeTile(badge, refresh),
                const SizedBox(height: 8),
                const Text('Bu etkinlik cihaz üzerinde çalışır; çevrim içi liderlik tablosu yoktur.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF85648B))),
              ],
            )),
          ]),
        )),
      ),
    );
  }

  // V9: The wheel and collection use their own save key; older progress
  // and offline gameplay mechanics are unchanged.
  void _openV9Wheel(StateSetter refresh) {
    final navContext = _navigatorKey.currentContext;
    if (navContext == null) return;
    _fx();
    showDialog<void>(
      context: navContext,
      builder: (dialogContext) => V9WheelDialog(
        progress: _v9,
        onSpin: (slot) {
          final reward = _v9.spin(slot, DateTime.now());
          if (reward == null) return null;
          setState(() {
            _v6.coins += reward.coins;
            _hammers += reward.hammers;
            _lineBlasts += reward.lines;
            _shuffles += reward.shuffles;
          });
          refresh(() {});
          _audio.play(CandySound.win);
          _save();
          return reward;
        },
      ),
    );
  }

  void _claimV9Color(int type, StateSetter refresh) {
    final coins = _v9.claimColor(type);
    if (coins == null) return;
    setState(() => _v6.coins += coins);
    refresh(() {});
    _audio.play(CandySound.win);
    _save();
  }

  Widget _v9DailyCard(StateSetter refresh) {
    final used = !_v9.canSpin(DateTime.now());
    final index = _v9.wheelIndex;
    return Container(
      key: const ValueKey('v9-wheel-card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Color(0xFFFFE4A6), Color(0xFFFFD7EE),
        ]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x33BD4596),
          blurRadius: 8, offset: Offset(0, 4))],
        border: Border.all(color: const Color(0xFFF7B94B), width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.casino_rounded, color: Color(0xFFB742BB), size: 29),
          SizedBox(width: 8),
          Expanded(child: Text('GÜNLÜK ŞANS ÇARKI',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900,
              color: Color(0xFF712179)))),
        ]),
        const SizedBox(height: 5),
        Text(used && index != null
            ? 'Bugünkü ödül: ${v9WheelRewards[index].name}'
            : 'Her gün bir ücretsiz çevirme ve sürpriz ödül!',
          style: const TextStyle(fontSize: 12,
              color: Color(0xFF855280))),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerRight,
          child: FilledButton.icon(
            key: const ValueKey('v9-open-wheel'),
            onPressed: () => _openV9Wheel(refresh),
            icon: const Icon(Icons.autorenew_rounded),
            label: Text(used ? 'ÇARKI GÖR' : 'ÇARKI ÇEVİR',
              style: const TextStyle(fontWeight: FontWeight.w900)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC32CB2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22))),
          ),
        ),
      ]),
    );
  }

  Widget _v9CollectionCard(StateSetter refresh) {
    return Container(
      key: const ValueKey('v9-collection-card'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Color(0xFFFFF5FD), Color(0xFFFFEAF2)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF6BF69), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x2CA42A79),
          blurRadius: 9, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.auto_awesome_rounded, color: Color(0xFFE83D9A), size: 24),
          SizedBox(width: 7),
          Expanded(child: Text('ŞEKER KOLEKSİYONU',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900,
              color: Color(0xFF6F257A)))),
        ]),
        const SizedBox(height: 4),
        const Text('Her renkten 45 şeker patlat, 100 🍬 kazan. Her renk ödülü bir kez alınır.',
          style: TextStyle(fontSize: 11, color: Color(0xFF7A5285))),
        for (var i = 0; i < v9CollectionColorNames.length; i++) ...[
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFDEA3), width: 1.3),
            ),
            child: Column(children: [
              Row(children: [
                Container(width: 25, height: 25,
                  decoration: BoxDecoration(color: candyPalette[i],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [BoxShadow(color: Color(0x4A4B246C),
                      blurRadius: 4, offset: Offset(0, 2))])),
                const SizedBox(width: 7),
                Expanded(child: Text(v9CollectionColorNames[i],
                  style: const TextStyle(fontWeight: FontWeight.w900,
                    fontSize: 13, color: Color(0xFF653174)))),
                Text('${_v9.colorCounts[i].clamp(0, v9CollectionGoal)}/$v9CollectionGoal',
                  style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w800, color: Color(0xFF733783))),
                const SizedBox(width: 5),
                SizedBox(width: 91, child: FilledButton(
                  key: ValueKey('v9-color-claim-$i'),
                  onPressed: _v9.canClaimColor(i)
                    ? () => _claimV9Color(i, refresh) : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    backgroundColor: const Color(0xFFFFCB59),
                    foregroundColor: const Color(0xFF692369),
                    disabledBackgroundColor: const Color(0xFFF0EAF2),
                    disabledForegroundColor: const Color(0xFF9C89A0),
                    minimumSize: const Size(82, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
                  child: FittedBox(child: Text(_v9.collectionClaims.contains(i)
                    ? 'ALINDI ✓' : '100 🍬 AL',
                    style: const TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w900))),
                )),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: LinearProgressIndicator(
                  value: (_v9.colorCounts[i] / v9CollectionGoal)
                    .clamp(0.0, 1.0).toDouble(),
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEDE4F1),
                  color: candyPalette[i],
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  // V8: rotating seasonal color hunt, chain-combo and unique-level missions.
  void _claimV8Mission(V8Mission mission, StateSetter refresh) {
    final reward = _v8.claim(mission, DateTime.now());
    if (reward == null) return;
    setState(() {
      _v6.coins += reward.coins;
      _hammers += reward.hammers;
      _shuffles += reward.shuffles;
    });
    refresh(() {});
    _audio.play(CandySound.win);
    _save();
  }

  Widget _v8SeasonCard(StateSetter refresh) {
    const labels = <V8Mission, String>{
      V8Mission.colorHunt: 'HEDEF RENKTE ŞEKER TOPLA',
      V8Mission.combos: 'ZİNCİR KOMBO YAP (x2+)',
      V8Mission.levelWins: 'FARKLI BÖLÜM TAMAMLA',
    };
    final color = candyPalette[_v8.targetType];
    return Container(
      key: const ValueKey('v8-season-center'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [
          Color(0xFFFCE2FF), Color(0xFFFFF0D0),
        ]),
        border: Border.all(color: const Color(0xFFE8B0EE), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🌈 SEZONLUK RENK AVI  •  V8',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
              color: Color(0xFF873599))),
        const SizedBox(height: 4),
        Text('Sezon: ${_v8.season}  •  Hedef: ${v8ColorNames[_v8.targetType]}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
              color: Color(0xFF87517F))),
        const SizedBox(height: 7),
        Row(children: [
          const Text('BU AYIN ŞEKERİ  ', style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 12)),
          Container(key: const ValueKey('v8-season-color'),
            width: 25, height: 25,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2)),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Text('Şekerleri patlat, görevleri bitir!',
            style: TextStyle(fontSize: 11))),
        ]),
        for (final plan in v8Missions) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text(labels[plan.mission]!,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                  color: Color(0xFF743C7D)))),
            Text('${_v8.progressFor(plan.mission).clamp(0, plan.goal)}/${plan.goal}',
              style: const TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (_v8.progressFor(plan.mission) / plan.goal)
                .clamp(0.0, 1.0).toDouble(),
            minHeight: 7, backgroundColor: const Color(0xFFE8D8E8),
            color: color,
          ),
          Row(children: [
            Expanded(child: Text('+${plan.reward.coins} 🍬'
              '${plan.reward.hammers > 0 ? '  +${plan.reward.hammers} çekiç' : ''}'
              '${plan.reward.shuffles > 0 ? '  +${plan.reward.shuffles} karıştır' : ''}',
              style: const TextStyle(fontSize: 11,
                  color: Color(0xFF71477D)))),
            TextButton(
              key: ValueKey('v8-claim-${plan.mission.name}'),
              onPressed: _v8.canClaim(plan.mission, DateTime.now())
                  ? () => _claimV8Mission(plan.mission, refresh) : null,
              child: Text(_v8.claimed.contains(plan.mission) ? 'ALINDI ✓' : 'ÖDÜLÜ AL'),
            ),
          ]),
        ],
        const Text('Ay değiştiğinde yeni sezon başlar. Çevrim dışı oynanır.',
          style: TextStyle(fontSize: 11, color: Color(0xFF79547C))),
      ]),
    );
  }

  Widget _v7WeeklyTile(int index, StateSetter refresh) {
    final tier = v7WeeklyTiers[index];
    final done = _v7.claimedWeeklyTiers.contains(index);
    final canClaim = _v7.canClaimWeekly(index, DateTime.now());
    final progress = _v7.completedThisWeek.length;
    final label = '${tier.reward.coins} 🍬'
        '${tier.reward.hammers > 0 ? '  •  +${tier.reward.hammers} çekiç' : ''}'
        '${tier.reward.shuffles > 0 ? '  •  +${tier.reward.shuffles} karıştırma' : ''}';
    return Card(color: Colors.white, margin: const EdgeInsets.only(top: 8),
      child: Padding(padding: const EdgeInsets.all(11), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('${tier.goal} FARKLI BÖLÜM',
              style: const TextStyle(fontWeight: FontWeight.w900,
                  color: Color(0xFF78398E)))),
            Text('${progress.clamp(0, tier.goal)}/${tier.goal}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 7),
          LinearProgressIndicator(
            value: (progress / tier.goal).clamp(0.0, 1.0).toDouble(),
            minHeight: 7, backgroundColor: const Color(0xFFF3E4F5),
            color: const Color(0xFFE979C3)),
          const SizedBox(height: 7),
          Row(children: [
            Expanded(child: Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF88568C)))),
            TextButton(
              key: ValueKey('v7-weekly-$index'),
              onPressed: canClaim ? () => _claimV7Week(index, refresh) : null,
              child: Text(done ? 'ALINDI ✓' : 'ÖDÜLÜ AL'),
            ),
          ]),
        ],
      )),
    );
  }

  Widget _v7BadgeTile(V7Badge badge, StateSetter refresh) {
    final progress = v7BadgeProgress(badge, _stars);
    final done = _v7.claimedBadges.contains(badge.id);
    final canClaim = _v7.canClaimBadge(badge, _stars);
    return Card(color: Colors.white, margin: const EdgeInsets.only(top: 8),
      child: Padding(padding: const EdgeInsets.all(11), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.workspace_premium_rounded,
              color: Color(0xFFF5B54F)),
            const SizedBox(width: 8),
            Expanded(child: Text(badge.title,
              style: const TextStyle(fontWeight: FontWeight.w900,
                  color: Color(0xFF78398E)))),
            Text('${progress.clamp(0, badge.goal)}/${badge.goal}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          Text(badge.description,
            style: const TextStyle(fontSize: 12, color: Color(0xFF775780))),
          const SizedBox(height: 7),
          LinearProgressIndicator(
            value: (progress / badge.goal).clamp(0.0, 1.0).toDouble(),
            minHeight: 6, backgroundColor: const Color(0xFFF3E4F5),
            color: const Color(0xFFEFB859)),
          Row(children: [
            Expanded(child: Text('+${badge.reward.coins} 🍬',
              style: const TextStyle(fontWeight: FontWeight.w700,
                  color: Color(0xFF88568C)))),
            TextButton(
              key: ValueKey('v7-badge-${badge.id}'),
              onPressed: canClaim ? () => _claimV7Badge(badge, refresh) : null,
              child: Text(done ? 'ALINDI ✓' : 'ROZETİ AL'),
            ),
          ]),
        ],
      )),
    );
  }

  void _howToPlay() {
    final navContext = _navigatorKey.currentContext;
    if (navContext == null) return;
    showDialog<void>(
      context: navContext,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF5FF),
        title: const Text('Nasıl Oynanır?',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF8133A0))),
        content: const Text(
          '• Bir şekeri yatay ya da dikey sürükle.\n\n'
          '• Aynı renkte en az 3 şekeri yan yana getir.\n\n'
          '• Eşleşen şekerler patlar; yukarıdakiler aşağı düşer.\n\n'
          '• 4 şeker: satır veya sütun patlatan çizgili şeker.\n\n'
          '• 5 şeker: renk bombası. Renk bombasını komşu bir şekerle değiştir.\n\n'
          '• İki özel şekeri yan yana değiştirerek büyük patlama yap.\n\n'
          '• Bölüm 3’ten itibaren buz iki darbede kırılır.\n\n'
          '• Çikolata eşleşmeleri engeller ve temizlenmezse yayılır.\n\n'
          '• Kilitli şekeri hareket ettiremezsin; komşu eşleşmeyle kilidi aç.\n\n'
          '• Hamlelerin bitmeden hedef puana ulaş veya istenen şekeri topla.\n\n'
          '• Çekiç, satır patlatma ve karıştırma güçlerini kullan.\n\n'
          '• Günlük hediye ve görevler için ana ekrandaki hediye simgesini aç.\n\n'
          '• Başarılı olduğunda yeni bölümler açılır.\n\n'
          '• V7: 120 bölüm ve 6 dünya devam ediyor.\n\n'
          '• İlk defa kazandığın yıldızlar şeker parası kazandırır.\n\n'
          '• Şeker dükkânından oyun parasıyla güçlendirici al.\n\n'
          '• Her 20. bölümü bitirince haritadaki dünya sandığını aç.\n\n'
          '• V7 etkinlik merkezi: Haftada farklı bölümler kazanıp ödül al.\n\n'
          '• V8 sezonluk renk avında hedef renkteki şekerleri topla, kombo yap ve bölüm bitir.\n\n'
          '• Başarım rozetlerini yıldız ve bölüm hedefleriyle aç.',
          style: TextStyle(height: 1.35, fontSize: 15),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('ANLADIM')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Şeker Bahçesi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC44EDD)),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _page == ViewPage.map
                    ? 'assets/images/v15_3_world.webp'
                    : 'assets/images/v15_3_world.webp',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) =>
                    const CustomPaint(painter: SceneryPainter()),
              ),
            ),
            Positioned.fill(child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .38, 1],
                  colors: [Color(0x08FFFFFF), Color(0x00FFFFFF), Color(0x0CFFCAEA)],
                ),
              ),
            )),
            SafeArea(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : switch (_page) {
                      ViewPage.home => _homePage(),
                      ViewPage.map => _mapPage(),
                      ViewPage.play => _playPage(),
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _homePage() {
    return LayoutBuilder(builder: (context, limits) {
      final compact = limits.maxHeight < 710;
      final small = limits.maxWidth < 370;
      return Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 0),
          child: Row(children: [
            _roundIcon(Icons.help_outline_rounded, _howToPlay),
            const SizedBox(width: 7),
            _roundIcon(Icons.card_giftcard_rounded, _openDailyRewards),
            const SizedBox(width: 7),
            _roundIcon(Icons.emoji_events_rounded, _openEventCenter),
            const Spacer(),
            _pill('🍬 ${_v6.coins}', const Color(0xFFB16A1F)),
            const SizedBox(width: 6),
            _roundIcon(_sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                _toggleSound),
          ]),
        ),
        const Spacer(flex: 2),
        // V14: true illustrated banner, not a static screenshot of the app.
        Image.asset(
          'assets/images/v15_logo_cutout.png',
          width: small ? 305 : 350,
          height: compact ? 195 : 220,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        SizedBox(height: compact ? 15 : 25),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final i in [1, 2, 3, 0, 5])
            Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
              child: CandyPiece(type: i, size: compact ? 49 : 57)),
        ]),
        const Spacer(flex: 2),
        _bigButton('▶   OYNA', () => _openGame(_continueLevel()),
          colorA: const Color(0xFF90F845), colorB: const Color(0xFF16AB34)),
        SizedBox(height: compact ? 9 : 15),
        _bigButton('🗺   BÖLÜMLER', () {
          _fx(); setState(() => _page = ViewPage.map);
        }, colorA: const Color(0xFFFF94CD),
           colorB: const Color(0xFFCE3CBA), small: true),
        const Spacer(flex: 2),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _homeMenuButton(Icons.storefront_rounded, 'DÜKKÂN', _openShop),
          _homeMenuButton(Icons.task_alt_rounded, 'GÖREVLER', _openDailyRewards),
          _homeMenuButton(Icons.card_giftcard_rounded, 'ETKİNLİK', _openEventCenter),
          _homeMenuButton(Icons.map_rounded, 'HARİTA',
              () => setState(() => _page = ViewPage.map)),
          _homeMenuButton(Icons.save_alt_rounded, 'YEDEK', _openBackupCenter),
        ]),
        SizedBox(height: compact ? 11 : 24),
      ]);
    });
  }

  // V12: portable manual backups survive reinstall only when the user saves
  // the copied code OUTSIDE the app (Notes, email, Drive, etc.).
  Future<void> _openBackupCenter() async {
    await _save();
    final navContext = _navigatorKey.currentContext;
    final prefs = _storage;
    if (!mounted || navContext == null || prefs == null) return;
    final values = <String, Object?>{
      for (final key in V12BackupCodec.keys)
        if (prefs.get(key) != null) key: prefs.get(key),
    };
    final code = V12BackupCodec.encode(values);
    await showDialog<void>(
      context: navContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('💾 Oyun yedeğim'),
        content: const SingleChildScrollView(
          child: Text('Bölümlerini, yıldızlarını, şeker paranı, '
              'güçlendiricilerini ve görevlerini yedekle. '
              'Kopyaladığın yedek kodunu NOTLAR veya e-posta gibi '
              'oyun dışındaki güvenli bir yere kaydet. '
              'Uygulamayı kaldırırsan sadece telefondaki kayıt silinebilir.'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              final current = _navigatorKey.currentContext;
              if (current != null && current.mounted) {
                ScaffoldMessenger.of(current).showSnackBar(const SnackBar(
                  content: Text('Yedek kodu kopyalandı. Şimdi Notlar’a yapıştırıp kaydet!'),
                ));
              }
            },
            child: const Text('KODU KOPYALA'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _restoreBackupDialog();
            },
            child: const Text('YEDEK GERİ YÜKLE'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('KAPAT'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreBackupDialog() async {
    final navContext = _navigatorKey.currentContext;
    if (navContext == null || !mounted) return;
    final controller = TextEditingController();
    final input = await showDialog<String>(
      context: navContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yedekten geri yükle'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Notlar’a kaydettiğin SB12- ile başlayan kodu yapıştır. '
                'Onay verene kadar mevcut kayıt değişmeyecek.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              autocorrect: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'SB12-...',
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İPTAL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('KODU KONTROL ET'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || input == null || input.trim().isEmpty) return;
    Map<String, Object> parsed;
    try {
      parsed = V12BackupCodec.decode(input);
    } catch (_) {
      final current = _navigatorKey.currentContext;
      if (current != null && current.mounted) {
        ScaffoldMessenger.of(current).showSnackBar(const SnackBar(
          content: Text('Yedek kodu geçersiz; hiçbir kayıt değiştirilmedi.'),
        ));
      }
      return;
    }
    final current = _navigatorKey.currentContext;
    if (current == null || !current.mounted) return;
    final approved = await showDialog<bool>(
      context: current,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kayıt üzerine yazılsın mı?'),
        content: Text('Yedekteki ${parsed['unlocked']}. bölüm ilerlemesi '
            've ödüller bu telefondaki ilerlemenin yerine geçecek. '
            'İşlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('EVET, GERİ YÜKLE'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    final prefs = _storage;
    if (prefs == null) return;
    for (final key in V12BackupCodec.keys) {
      final value = parsed[key];
      if (value == null) {
        await prefs.remove(key);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    }
    _stars.clear();
    _game = null;
    _daily = DailyProgress.fresh(DateTime.now());
    _v6 = V6Progress();
    _v7 = V7Progress(today: DateTime.now());
    _v8 = V8SeasonProgress(today: DateTime.now());
    _v9 = V9RewardsProgress(today: DateTime.now());
    await _load();
    await _audio.setEnabled(_sound);
    if (!mounted) return;
    setState(() { _page = ViewPage.home; _result = null; });
    final after = _navigatorKey.currentContext;
    if (after != null && after.mounted) {
      ScaffoldMessenger.of(after).showSnackBar(const SnackBar(
        content: Text('Yedek geri yüklendi. İlerlemen hazır!'),
      ));
    }
  }

  Widget _homeMenuButton(IconData icon, String title, VoidCallback action) =>
      GestureDetector(
        onTap: action,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 60, height: 57,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFFFFF8D9), Color(0xFFFFA8D4), Color(0xFFED67AE)]),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [BoxShadow(color: Color(0x674C2857),
                  blurRadius: 11, offset: Offset(0, 5))],
            ),
            child: Icon(icon, size: 29, color: const Color(0xFF8D3584)),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xF9FFF8F1),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFFFD692), width: 1.2),
            ),
            child: Text(title, maxLines: 1, textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF5D1B69),
                fontSize: 10, fontWeight: FontWeight.w900, height: 1.0)),
          ),
        ]),
      );

  // V15.1 readability panels: scenery stays, text contrast improves.
  Widget _mapPage() {
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 9, 16, 12),
        child: Row(children: [
          _roundIcon(Icons.arrow_back_rounded,
              () => setState(() => _page = ViewPage.home)),
          const SizedBox(width: 12),
          Expanded(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xF5FFF6EB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD88C), width: 1.6),
              boxShadow: const [BoxShadow(color: Color(0x4D52246A),
                blurRadius: 7, offset: Offset(0, 3))],
            ),
            child: Text('Şeker Yolu • V15.3', maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _titleStyle(20, const Color(0xFF671C73))),
          )),
          _roundIcon(Icons.emoji_events_rounded, _openEventCenter),
          const SizedBox(width: 6),
          _roundIcon(Icons.storefront_rounded, _openShop),
        ]),
      ),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 17),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _pill('SEVİYE ${math.min(_unlocked, v6LevelCount)} / $v6LevelCount',
                const Color(0xFFE24F82)),
            _pill('🍬 ${_v6.coins}', const Color(0xFF8335A3)),
          ])),
      const SizedBox(height: 8),
      Expanded(child: ListView(
        key: const ValueKey('v6-world-map'),
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
        children: [for (final world in v6Worlds) _worldPanel(world)],
      )),
    ]);
  }

  /// V12: scenic, winding path with the same level actions and keys as V11.
  Widget _worldPanel(V6World world) {
    final completed = [for (var level = world.start; level <= world.end; level++)
      if ((_stars[level] ?? 0) > 0) level].length;
    final claimed = _v6.claimedChests.contains(world.end);
    final canClaim = _v6.canClaimChest(world.end, _stars);
    return Container(
      key: ValueKey('v6-world-${world.start}'),
      margin: const EdgeInsets.only(bottom: 19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF91C4), Color(0xFFFFF4C8), Color(0xFFCE67BA)]),
        border: Border.all(color: const Color(0xFFFFE7A1), width: 6),
        boxShadow: const [BoxShadow(color: Color(0x66471662),
          blurRadius: 17, offset: Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                Color(0xFFFF84B8), Color(0xFFED3A95), Color(0xFF9A2CA7)])),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🌸 ${world.name.toUpperCase()}',
                  style: const TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w900, shadows: [
                      Shadow(color: Color(0xFF4F135A), blurRadius: 4, offset: Offset(0, 2)),
                      Shadow(color: Color(0xFF4F135A), blurRadius: 3, offset: Offset(0, -1))])),
                Text('${world.subtitle}  •  $completed / 20 tamamlandı',
                  style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w900, fontSize: 13,
                    shadows: [Shadow(color: Color(0xFF52185F),
                      blurRadius: 4, offset: Offset(0, 2))])),
              ]),
          ),
          SizedBox(height: V12PathGeometry.height,
            child: LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(children: [
                const Positioned.fill(child: Image(
                  image: AssetImage('assets/images/v15_3_world.webp'),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                )),
                const Positioned.fill(child: DecoratedBox(
                  decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x06FFFFFF), Color(0x06FFE6AA), Color(0x09D6F18F)])),
                )),
                const Positioned.fill(child: IgnorePointer(
                  child: CustomPaint(painter: V12RoadPainter()),
                )),
                for (var i = 0; i < v6LevelsPerWorld; i++)
                  Positioned(
                    left: V12PathGeometry.levelCenter(i, width).dx - 31,
                    top: V12PathGeometry.levelCenter(i, width).dy - 31,
                    width: 62,
                    height: 72,
                    child: _levelNode(world.start + i),
                  ),
              ]);
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 13, 11, 14),
            child: SizedBox(width: double.infinity,
              child: OutlinedButton.icon(
                key: ValueKey('v6-chest-${world.end}'),
                onPressed: canClaim ? () => _claimWorldChest(world.end) : null,
                icon: Icon(claimed ? Icons.check_circle_rounded : Icons.inventory_2_rounded),
                label: Text(claimed ? 'DÜNYA SANDIĞI ALINDI ✓'
                    : canClaim ? 'DÜNYA SANDIĞINI AÇ  +150 🍬'
                    : 'SANDIK: ${world.end}. BÖLÜMÜ BİTİR'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF713180),
                  backgroundColor: const Color(0xFFFFF2D9),
                  disabledForegroundColor: const Color(0xFF755481),
                  disabledBackgroundColor: const Color(0xFFEBD4EE),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _levelNode(int level) {
    final unlocked = level <= _unlocked;
    final stars = (_stars[level] ?? 0).clamp(0, 3).toInt();
    return GestureDetector(
      key: ValueKey('v6-level-$level'),
      onTap: unlocked ? () => _openGame(level) : null,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Expanded(child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: unlocked ? const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFFFDFF0), Color(0xFFFF57AF), Color(0xFFD51979)])
                : const LinearGradient(colors: [Color(0xFF8F839B),
                    Color(0xFF665878)]),
            border: Border.all(color: const Color(0xFFFFF1A8), width: 3.3),
            boxShadow: const [
              BoxShadow(color: Color(0xB15E1762), blurRadius: 14, offset: Offset(0, 6)),
              BoxShadow(color: Color(0xAAFFFFFF), blurRadius: 9, offset: Offset(0, -2))],
          ),
          child: Center(child: unlocked
            ? Text('$level', style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900,
                fontSize: 18, shadows: [Shadow(color: Color(0x995B1359),
                    blurRadius: 3, offset: Offset(0, 2))]))
            : const Icon(Icons.lock_rounded, color: Colors.white, size: 18)),
        )),
        Text(stars == 0 ? '☆☆☆' :
            '${List.filled(stars, '★').join()}${List.filled(3 - stars, '☆').join()}',
          style: const TextStyle(fontSize: 12,
            color: Color(0xFFFFE88A), fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _playPage() {
    final g = _game!;
    return LayoutBuilder(builder: (context, constraints) {
      final side = math.min(
          math.min(constraints.maxWidth - 20, 440.0),
          constraints.maxHeight * .45);
      _boardCell = (side - 22) / gridSize;
      final compact = constraints.maxHeight < 710;
      return Stack(children: [
        Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 5, 12, 0),
            child: Row(children: [
              _roundIcon(Icons.arrow_back_rounded, _leaveGame),
              const SizedBox(width: 10),
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xF8FFF7ED),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD99D), width: 1.5),
                  boxShadow: const [BoxShadow(color: Color(0x3D58266B),
                    blurRadius: 8, offset: Offset(0, 3))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BÖLÜM ${g.level}  •  V15.3', maxLines: 1,
                      style: const TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w900, letterSpacing: .5,
                        color: Color(0xFF64236D))),
                    Text(g.plan.name, maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF631A77))),
                  ],
                ),
              )),
              _roundIcon(Icons.lightbulb_rounded, _showHint),
              const SizedBox(width: 6),
              _roundIcon(Icons.help_outline_rounded, _howToPlay),
              const SizedBox(width: 6),
              _roundIcon(_sound ? Icons.volume_up_rounded :
                  Icons.volume_off_rounded,
                  _toggleSound),
            ]),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 17),
            padding: EdgeInsets.symmetric(horizontal: 13,
                vertical: compact ? 7 : 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFFFFFFFF), Color(0xFFFFF6DD), Color(0xFFFFD8EB)]),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFFE1A5), width: 3.5),
              boxShadow: const [BoxShadow(color: Color(0x309D359E),
                  blurRadius: 12, offset: Offset(0, 5))],
            ),
            child: Row(children: [
              Container(width: 69, height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFFFF83B1), Color(0xFFD73383)]),
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: const [BoxShadow(color: Color(0x50ED7950),
                      blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Text('${g.moves}', style: const TextStyle(fontSize: 31,
                      height: 1, fontWeight: FontWeight.w900,
                      color: Colors.white)),
                  const Text('HAMLE', style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w900, color: Colors.white)),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (g.plan.isCollection) ...[
                      CandyPiece(type: g.plan.focusType, size: 29),
                      const SizedBox(width: 5),
                    ],
                    Expanded(child: Text(
                      g.plan.isCollection
                          ? 'TOPLA: ${g.collected} / ${g.plan.target}'
                          : 'PUAN: ${g.score} / ${g.plan.target}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900,
                          fontSize: 12, color: Color(0xFF8A399A)),
                    )),
                  ]),
                  const SizedBox(height: 5),
                  ClipRRect(borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: g.progress, minHeight: 13,
                      backgroundColor: const Color(0xFFFFECBD),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF9D25)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(3, (i) => Icon(Icons.star_rounded,
                        color: g.progress >= (i + 1) / 3
                            ? const Color(0xFFFFC32D)
                            : const Color(0xFFE6D7E8), size: 21)),
                  ),
                ],
              )),
            ]),
          ),
          AnimatedBuilder(
            animation: _burstAnimation,
            child: _gameBoard(side),
            builder: (context, child) {
              final p = _burstAnimation.value;
              final shake = math.sin(p * math.pi * 22) *
                  (1 - p) * (p < .48 ? 2.8 : .5);
              return Transform.translate(
                offset: Offset(shake, -shake * .36), child: child);
            },
          ),
          Column(children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: EdgeInsets.symmetric(horizontal: 13,
                  vertical: compact ? 5 : 7),
              decoration: BoxDecoration(
                color: const Color(0xF5FFF8ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD58E), width: 1.5),
                boxShadow: const [BoxShadow(color: Color(0x4D662C77),
                  blurRadius: 9, offset: Offset(0, 3))],
              ),
              child: Text(_power == PowerMode.none ? _message :
                      'Patlatmak istediğin şekere dokun!',
                  textAlign: TextAlign.center,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900,
                      fontSize: compact ? 13 : 15,
                      color: const Color(0xFF5A166C))),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _powerButton(Icons.auto_fix_high_rounded, 'ÇEKİÇ',
                    _hammers, PowerMode.hammer,
                    const Color(0xFFF75A9A)),
                _powerButton(Icons.flash_on_rounded, 'SATIR',
                    _lineBlasts, PowerMode.line,
                    const Color(0xFFFFA63D)),
                _powerButton(Icons.shuffle_rounded, 'KARIŞTIR',
                    _shuffles, PowerMode.none,
                    const Color(0xFF8D65E9), shuffle: true),
              ],
            ),
          ]),
          Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 9),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xF6FFF8EB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD597), width: 1.3),
              ),
              child: Text(g.remainingObstacles > 0
                  ? 'BUZ: ${g.countObstacle(ObstacleKind.ice)}   ÇİKOLATA: ${g.countObstacle(ObstacleKind.chocolate)}   KİLİT: ${g.countObstacle(ObstacleKind.lock)}'
                  : '4 eşleşme: çizgili • 5 eşleşme: renk bombası',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: compact ? 10 : 11,
                      color: const Color(0xFF5E206E),
                      fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
        if (_result != null) Positioned.fill(child: _resultOverlay(g)),
        if (_result == true) Positioned.fill(child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _winAnimation,
            builder: (context, _) => CustomPaint(
              painter: V5CelebrationPainter(progress: _winAnimation.value),
            ),
          ),
        )),
      ]);
    });
  }

  Widget _gameBoard(double side) {
    final g = _game!;
    const inset = 5.0;
    final cell = _boardCell;
    return Container(
      width: side, height: side,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFFE78C), Color(0xFFFFB4DA), Color(0xFFFFF0B1)]),
        borderRadius: BorderRadius.circular(29),
        border: Border.all(color: const Color(0xFFFFF3C4), width: 6),
        boxShadow: const [
          BoxShadow(color: Color(0x994D167A), blurRadius: 22, offset: Offset(0, 12)),
          BoxShadow(color: Color(0xAAFFFFFF), blurRadius: 6,
              offset: Offset(0, -3)),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(21),
        child: Stack(children: [
          const Positioned.fill(child: DecoratedBox(
            decoration: BoxDecoration(gradient: RadialGradient(
              center: Alignment(-.55, -.8), radius: 1.5,
              colors: [Color(0xFF6686C6), Color(0xFF2D528F), Color(0xFF152D5C)],
            )),
          )),
          ...[for (var r = 0; r < gridSize; r++)
            for (var c = 0; c < gridSize; c++)
              Positioned(left: inset + c * cell, top: inset + r * cell,
                width: cell, height: cell,
                child: Container(
                  margin: const EdgeInsets.all(1.1),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: (r + c).isEven
                        ? const [Color(0xFF5274AD), Color(0xFF294C84)]
                        : const [Color(0xFF476BA9), Color(0xFF234476)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xA2ABC9FC), width: 1.1),
                  ),
                ),
              ),
          ],
          if (_selected != null && !_busy)
            Positioned(left: inset + _selected!.col * cell,
                top: inset + _selected!.row * cell,
                width: cell, height: cell,
                child: Container(decoration: BoxDecoration(
                  color: const Color(0x66FFF7B6),
                  border: Border.all(color: Colors.white, width: 3.2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Color(0xDDFFF5A8), blurRadius: 14, spreadRadius: 1)],
                )),
            ),
          ...[for (var r = 0; r < gridSize; r++)
            for (var c = 0; c < gridSize; c++)
              if (g.board[r][c] != null)
                AnimatedPositioned(
                  key: ValueKey('candy-${g.board[r][c]!.id}'),
                  duration: const Duration(milliseconds: 355),
                  curve: Curves.easeOutCubic,
                  left: inset + c * cell, top: inset + r * cell,
                  width: cell, height: cell,
                  child: _candyOnBoard(g.board[r][c]!, r, cell),
                ),
          ],
          // Animated obstacle overlays: chocolate blocks swaps, ice takes
          // two hits, and locks require a blast or neighbouring match.
          ...[for (var r = 0; r < gridSize; r++)
            for (var c = 0; c < gridSize; c++)
              if (g.obstacles[r][c] > 0)
                Positioned(
                  left: inset + c * cell, top: inset + r * cell,
                  width: cell, height: cell,
                  child: IgnorePointer(child: _obstacleTile(g.obstacles[r][c])),
                ),
          ],
          if (_hintCells.isNotEmpty)
            Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(
              animation: _hintAnimation,
              builder: (context, _) => Stack(children: [
                for (final spot in _hintCells)
                  Positioned(
                    left: inset + spot.col * cell,
                    top: inset + spot.row * cell,
                    width: cell,
                    height: cell,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFFFFD34F).withValues(
                          alpha: .15 + .22 * _hintAnimation.value),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: .7 + .3 * _hintAnimation.value),
                          width: 2.5 + _hintAnimation.value * 1.8),
                        boxShadow: [BoxShadow(
                          color: const Color(0xFFFFE761).withValues(
                            alpha: .45 + _hintAnimation.value * .40),
                          blurRadius: 10 + _hintAnimation.value * 13,
                          spreadRadius: 2 + _hintAnimation.value * 2,
                        )],
                      ),
                    ),
                  ),
              ]),
            ))),
          Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(
            animation: _burstAnimation,
            builder: (context, child) => CustomPaint(
              size: Size.square(side),
              painter: SparklePainter(
                progress: _burstAnimation.value,
                centers: _burstPositions,
                colors: _burstColors.isEmpty ? [Colors.white] : _burstColors,
              ),
            ),
          ))),
          Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(
            animation: _burstAnimation,
            builder: (context, _) => CustomPaint(
              painter: V5ScorePainter(
                progress: _burstAnimation.value,
                centers: _burstPositions,
                points: _burstPoints,
                chain: _comboCount,
              ),
            ),
          ))),
          Positioned.fill(child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _burstAnimation,
              builder: (context, _) {
                final p = _burstAnimation.value;
                final visibility =
                    (1 - ((p - .47) / .53)).clamp(0.0, 1.0).toDouble();
                final pop = Curves.elasticOut.transform(
                    (p * 3.1).clamp(0.0, 1.0).toDouble());
                final scale = .57 + pop * .54;
                return Center(child: Opacity(
                  opacity: _comboBanner.isEmpty ? 0 : visibility,
                  child: Transform.rotate(
                    angle: math.sin(p * math.pi * 5) * (1 - p) * .045,
                    child: Transform.scale(scale: scale,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: side * .90),
                        padding: EdgeInsets.symmetric(
                            horizontal: side * .042, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(0xFFE8419C), Color(0xFFAD43C9),
                          ]),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [
                            BoxShadow(color: Color(0xB0FFB236), blurRadius: 18,
                                spreadRadius: 3),
                            BoxShadow(color: Color(0xAA7325BC), blurRadius: 13,
                                offset: Offset(0, 6)),
                          ],
                        ),
                        child: Text(_comboBanner,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: side * .066,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .4,
                            color: const Color(0xFFFFF9C2),
                            shadows: const [
                              Shadow(color: Color(0xFFFF5D52), blurRadius: 6,
                                  offset: Offset(0, 2)),
                              Shadow(color: Color(0xFF71217E), blurRadius: 4,
                                  offset: Offset(0, 3)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ));
              },
            ),
          )),
          Positioned.fill(child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => _tapBoard(details.localPosition),
            onPanStart: (details) {
              _dragStart = _touchCell(details.localPosition);
              _dragDistance = Offset.zero;
            },
            onPanUpdate: (details) => _dragDistance += details.delta,
            onPanEnd: (_) => _finishDrag(),
            onPanCancel: () => _dragStart = null,
          )),
        ]),
      ),
    );
  }

  Widget _obstacleTile(int code) {
    final isIce = code <= 2;
    final isChoco = code == 3;
    return Padding(
      padding: const EdgeInsets.all(1.8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isIce
                ? [const Color(0x77F4FFFF), const Color(0x779BCFEF)]
                : isChoco
                    ? [const Color(0xFFEAA071), const Color(0xFF753352)]
                    : [const Color(0x99885ED0), const Color(0xBB361E71)],
          ),
          border: Border.all(
            color: isIce ? const Color(0xDDFFFFFF)
                : isChoco ? const Color(0xFFFFD09F)
                : const Color(0xFFFFE39A),
            width: code == 2 ? 2.7 : 1.5,
          ),
          boxShadow: const [BoxShadow(color: Color(0x55281557), blurRadius: 3)],
        ),
        child: Center(
          child: isIce
              ? Icon(code == 2 ? Icons.ac_unit_rounded : Icons.auto_awesome,
                  size: _boardCell * .43, color: Colors.white,
                  shadows: const [Shadow(color: Color(0xFF54B6EE), blurRadius: 5)])
              : isChoco
                  ? Icon(Icons.grid_view_rounded, size: _boardCell * .65,
                      color: const Color(0xFFFFD7A0))
                  : Icon(Icons.lock_rounded, size: _boardCell * .51,
                      color: const Color(0xFFFFE99B),
                      shadows: const [Shadow(color: Color(0xFF41206B), blurRadius: 4)]),
        ),
      ),
    );
  }

  /// Existing candy IDs stay in AnimatedPositioned for smooth gravity;
  /// freshly spawned IDs fall in from above instead of popping in place.
  Widget _candyOnBoard(Candy candy, int row, double cell) {
    final vanishing = _vanishing.contains(candy.id);
    final newborn = _newborn.contains(candy.id);
    final art = Center(child: CandyPiece(type: candy.type,
      special: candy.special, size: cell * .99));
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: vanishing ? 0 : 1,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        scale: vanishing ? 1.28 : 1,
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          turns: vanishing ? .09 : 0,
          child: newborn
            ? TweenAnimationBuilder<double>(
                key: ValueKey('fall-${candy.id}'),
                tween: Tween(begin: -(row + 3) * cell, end: 0),
                duration: const Duration(milliseconds: 425),
                curve: Curves.easeOutBack,
                builder: (context, dy, child) => Transform.translate(
                  offset: Offset(0, dy), child: child),
                child: art,
              )
            : art,
        ),
      ),
    );
  }

  Widget _powerButton(IconData icon, String label, int count,
      PowerMode mode, Color color, {bool shuffle = false}) {
    final active = !shuffle && _power == mode;
    final available = count > 0;
    return GestureDetector(
      onTap: available && !_busy && _result == null
          ? () {
              if (shuffle) { _shuffle(); return; }
              setState(() => _power = active ? PowerMode.none : mode);
              _fx();
            }
          : null,
      child: Opacity(opacity: available ? 1 : .44,
        child: Column(children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 61, height: 59,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.lerp(color, Colors.white, .55)!, color, Color.lerp(color, Colors.black, .12)!]),
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: active
                    ? const Color(0xFFFFFF58) : const Color(0xFFFFEC9C),
                    width: active ? 4 : 2.8),
                boxShadow: const [BoxShadow(color: Color(0x889E4093),
                    blurRadius: 13, offset: Offset(0, 6))],
              ),
              child: Padding(padding: const EdgeInsets.all(5),
                child: Image.asset(
                  shuffle ? 'assets/images/v14_shuffle.webp'
                      : mode == PowerMode.hammer
                          ? 'assets/images/v14_hammer.webp'
                          : 'assets/images/v14_line.webp',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                )),
            ),
            Positioned(right: -7, top: -7,
              child: Container(width: 23, height: 23,
                decoration: BoxDecoration(color: const Color(0xFFFFE35D),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.6)),
                child: Center(child: Text('$count', style: const TextStyle(
                    color: Color(0xFF873271),
                    fontSize: 12, fontWeight: FontWeight.w900))),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xF8FFF5E9),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFFFD598), width: 1.1),
            ),
            child: Text(label, maxLines: 1, style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w900,
                color: Color(0xFF5A1D69))),
          ),
        ]),
      ),
    );
  }

  Widget _resultOverlay(MatchEngine g) => LevelResultOverlay(
    key: ValueKey('result-${g.level}-${_result == true}'),
    won: _result == true,
    level: g.level,
    score: g.score,
    stars: g.stars,
    lastLevel: g.level >= v6LevelCount,
    bonusShuffle: _threeStarPrize,
    onPrimary: () {
      if (_result == true && g.level >= v6LevelCount) {
        setState(() { _result = null; _page = ViewPage.map; });
      } else {
        _openGame(_result == true ? g.level + 1 : g.level);
      }
    },
    onMap: () => setState(() {
      _result = null;
      _page = ViewPage.map;
    }),
  );

  TextStyle _titleStyle(double size, Color color) => TextStyle(
    fontSize: size, height: .98, fontWeight: FontWeight.w900,
    letterSpacing: -.9, color: color,
    shadows: const [
      Shadow(color: Colors.white, blurRadius: 1, offset: Offset(-1.4, -2)),
      Shadow(color: Color(0x664E266B), blurRadius: 3, offset: Offset(2.5, 4)),
    ],
  );

  Widget _roundIcon(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFEFF8)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1.8),
          boxShadow: const [
            BoxShadow(color: Color(0x40FFA6D7), blurRadius: 10, offset: Offset(0, 3)),
            BoxShadow(color: Color(0x309D45A5), blurRadius: 6, offset: Offset(0, 3))]),
      child: Icon(icon, color: const Color(0xFFE54893), size: 24),
    ),
  );

  Widget _pill(String text, Color shade) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFFFF0F8)]),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [BoxShadow(color: Color(0x28C96CC3), blurRadius: 7, offset: Offset(0, 3))],
    ),
    child: Text(text, maxLines: 1,
      style: TextStyle(color: shade, fontSize: 13,
        fontWeight: FontWeight.w900, height: 1.0)),
  );

  Widget _bigButton(String label, VoidCallback action,
      {bool small = false,
       Color colorA = const Color(0xFF95EF46),
       Color colorB = const Color(0xFF1AAD36)}) {
    return GestureDetector(
      onTap: action,
      child: Container(
        width: small ? 250 : 285,
        height: small ? 57 : 74,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter,
              end: Alignment.bottomCenter, colors: [Color.lerp(colorA, Colors.white, .18)!, colorA, colorB]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFF4D9), width: 3),
          boxShadow: [
            BoxShadow(color: colorB.withValues(alpha: .38), blurRadius: 16, offset: const Offset(0, 8)),
            const BoxShadow(color: Color(0x26FFFFFF), blurRadius: 2, offset: Offset(0, -2)),
          ],
        ),
        child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white,
                fontSize: small ? 20 : 26,
                fontWeight: FontWeight.w900, letterSpacing: 1.1,
                shadows: const [Shadow(color: Color(0xAA833C60),
                    blurRadius: 2, offset: Offset(0, 2))])),
      ),
    );
  }
}
