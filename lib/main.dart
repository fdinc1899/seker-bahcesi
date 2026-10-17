import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'candy_art.dart';
import 'game_engine.dart';

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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
  PowerMode _power = PowerMode.none;
  Cell? _selected;
  Cell? _dragStart;
  Offset _dragDistance = Offset.zero;
  String _message = 'Üç veya daha fazla şekeri eşleştir!';
  Set<int> _vanishing = {};
  Set<int> _newborn = {};
  List<Offset> _burstPositions = [];
  List<Color> _burstColors = [];
  late final AnimationController _burstAnimation;
  double _boardCell = 40;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _burstAnimation = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 560));
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _save();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _burstAnimation.dispose();
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
      final progress = prefs.getString('stars');
      if (progress != null) {
        (jsonDecode(progress) as Map<String, dynamic>).forEach((key, value) {
          _stars[int.parse(key)] = (value as num).toInt();
        });
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
    final g = _game;
    if (g != null && g.moves > 0 && !g.won) {
      await prefs.setString('session', jsonEncode(g.toJson()));
    } else {
      await prefs.remove('session');
    }
  }

  void _fx({bool strong = false}) {
    if (!_sound) return;
    SystemSound.play(SystemSoundType.click);
    if (strong) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _openGame(int level) {
    if (level > _unlocked || level < 1 || level > 60) return;
    setState(() {
      if (_game == null || _game!.level != level ||
          _game!.won || _game!.moves <= 0) {
        _game = MatchEngine(level);
      }
      _page = ViewPage.play;
      _result = null;
      _busy = false;
      _selected = null;
      _power = PowerMode.none;
      _message = 'Şekerleri sürükle ve eşleştir!';
    });
    _fx();
    _save();
  }

  void _leaveGame() {
    if (_busy) return;
    setState(() {
      _page = ViewPage.home;
      _result = null;
      _power = PowerMode.none;
    });
    _save();
  }

  Future<void> _trySwap(Cell a, Cell b) async {
    final g = _game;
    if (g == null || _busy || _result != null ||
        !g.inBounds(a) || !g.inBounds(b) || !g.neighbors(a, b)) return;
    setState(() {
      _busy = true;
      _selected = null;
      _message = '';
      g.swap(a, b);
    });
    await Future<void>.delayed(const Duration(milliseconds: 205));
    if (!mounted) return;
    if (g.matches().isEmpty) {
      setState(() {
        g.swap(a, b);
        _message = 'Bu hamle eşleşme oluşturmuyor.';
      });
      await Future<void>.delayed(const Duration(milliseconds: 190));
      if (mounted) setState(() => _busy = false);
      return;
    }
    g.moves--;
    _fx(strong: true);
    await _resolve();
  }

  Future<void> _resolve({Set<Cell>? special}) async {
    final g = _game;
    if (g == null) return;
    var chain = 1;
    var matched = special ?? g.matches();
    while (matched.isNotEmpty && chain <= 25) {
      _burstPositions = matched
          .map((cell) => Offset(
              (cell.col + .5) * _boardCell + 5,
              (cell.row + .5) * _boardCell + 5))
          .toList();
      _burstColors = matched.map((cell) {
        final candy = g.board[cell.row][cell.col];
        return candyPalette[candy?.type ?? 0];
      }).toList();
      setState(() {
        _vanishing = matched
            .map((cell) => g.board[cell.row][cell.col]?.id)
            .whereType<int>()
            .toSet();
        _message = chain > 1 ? 'SÜPER KOMBO x$chain!' :
            (matched.length >= 5 ? 'MUHTEŞEM!' : 'HARİKA!');
      });
      _burstAnimation.forward(from: 0);
      await Future<void>.delayed(const Duration(milliseconds: 230));
      if (!mounted) return;
      g.clear(matched, chain);
      final ids = g.collapse();
      setState(() {
        _vanishing = {};
        _newborn = ids.toSet();
      });
      await Future<void>.delayed(const Duration(milliseconds: 255));
      if (!mounted) return;
      setState(() => _newborn = {});
      matched = g.matches();
      chain++;
    }
    if (!g.hasMove()) {
      g.newBoard();
      setState(() => _message = 'Yeni şekerler karıştırıldı!');
    }
    if (g.won) {
      _unlocked = math.max(_unlocked, math.min(60, g.level + 1));
      _stars[g.level] = math.max(_stars[g.level] ?? 0, g.stars);
      setState(() {
        _result = true;
        _message = 'BÖLÜM TAMAMLANDI!';
      });
      _fx(strong: true);
    } else if (g.moves <= 0) {
      setState(() {
        _result = false;
        _message = 'Hamlelerin tükendi!';
      });
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
      g.moves--;
    });
    _fx(strong: true);
    await _resolve(special: cells);
  }

  void _shuffle() {
    final g = _game;
    if (g == null || _busy || _result != null || _shuffles <= 0) return;
    setState(() {
      _shuffles--;
      _power = PowerMode.none;
      _selected = null;
      g.newBoard();
      _message = 'Şekerler yeniden karıştı!';
    });
    _fx();
    _save();
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

  void _howToPlay() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF5FF),
        title: const Text('Nasıl Oynanır?',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF8133A0))),
        content: const Text(
          '• Bir şekeri yatay ya da dikey sürükle.\n\n'
          '• Aynı renkte en az 3 şekeri yan yana getir.\n\n'
          '• Eşleşen şekerler patlar; yukarıdakiler aşağı düşer.\n\n'
          '• Hamlelerin bitmeden hedef puana ulaş veya istenen şekeri topla.\n\n'
          '• Çekiç, satır patlatma ve karıştırma güçlerini kullan.\n\n'
          '• Başarılı olduğunda yeni bölümler açılır.',
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
      title: 'Şeker Bahçesi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC44EDD)),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: SceneryPainter())),
            Positioned.fill(child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0x30FFFFFF), Color(0x00FFFFFF), Color(0x60C9328B)],
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
      final compact = limits.maxHeight < 690;
      return Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 18, 0),
          child: Row(children: [
            _roundIcon(Icons.help_outline_rounded, _howToPlay),
            const Spacer(),
            _pill('★ ${_stars.values.fold<int>(0, (a, b) => a + b)}',
                const Color(0xFFEF8C19)),
            const SizedBox(width: 9),
            _roundIcon(_sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                () { setState(() => _sound = !_sound); _save(); }),
          ]),
        ),
        const Spacer(),
        SizedBox(
          height: compact ? 148 : 197,
          child: Stack(alignment: Alignment.center, children: [
            Positioned(left: 20, top: 27,
              child: Transform.rotate(angle: -.22,
                  child: const CandyPiece(type: 1, size: 126))),
            Positioned(right: 12, top: 1,
              child: Transform.rotate(angle: .2,
                  child: const CandyPiece(type: 2, size: 126))),
            Positioned(top: compact ? 45 : 67,
                child: const CandyPiece(type: 3, size: 116)),
            Positioned(right: 36, bottom: -10,
                child: const CandyPiece(type: 5, size: 74)),
            Positioned(left: 37, bottom: -9,
                child: const CandyPiece(type: 0, size: 68)),
          ]),
        ),
        SizedBox(height: compact ? 8 : 18),
        Text('ŞEKER', textAlign: TextAlign.center,
            style: _titleStyle(compact ? 54 : 66, const Color(0xFFF5388C))),
        Text('BAHÇESİ', textAlign: TextAlign.center,
            style: _titleStyle(compact ? 51 : 62, const Color(0xFF8233CB))),
        const SizedBox(height: 13),
        const Text('TATLI EŞLEŞMELERİN DÜNYASI',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF784184), fontSize: 12,
                fontWeight: FontWeight.w900, letterSpacing: 2)),
        const Spacer(),
        _bigButton('▶  OYNA', () => _openGame(_game?.level ?? _unlocked),
            colorA: const Color(0xFFFFB83C),
            colorB: const Color(0xFFFF653D)),
        const SizedBox(height: 14),
        _bigButton('BÖLÜMLER', () { _fx(); setState(() => _page = ViewPage.map); },
            colorA: const Color(0xFFB972F8),
            colorB: const Color(0xFF8137C8), small: true),
        const Spacer(),
        _pill('🍬  60 BÖLÜM     ★  BONUS GÜÇLER', const Color(0xFF8335A3)),
        SizedBox(height: compact ? 15 : 35),
      ]);
    });
  }

  Widget _mapPage() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 12),
        child: Row(children: [
          _roundIcon(Icons.arrow_back_rounded,
              () => setState(() => _page = ViewPage.home)),
          const SizedBox(width: 12),
          Expanded(child: Text('Şeker Yolu',
              style: _titleStyle(31, const Color(0xFF8B36B5)))),
          _pill('$_unlocked / 60', const Color(0xFFDA5A82)),
        ]),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 7),
        child: Text('Bölüm seç, yıldızlarını topla ve yeni dünyaları keşfet!',
            style: TextStyle(color: Color(0xFF844D93),
                fontWeight: FontWeight.w700), textAlign: TextAlign.center),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 38),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, crossAxisSpacing: 10,
            mainAxisSpacing: 18, childAspectRatio: .83),
          itemCount: 60,
          itemBuilder: (context, index) {
            final level = index + 1;
            final unlocked = level <= _unlocked;
            final stars = _stars[level] ?? 0;
            return GestureDetector(
              onTap: unlocked ? () => _openGame(level) : null,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Expanded(child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: unlocked
                            ? [candyPalette[index % candyTypes],
                               const Color(0xFFB333AA)]
                            : [const Color(0xFFC5B1D7),
                               const Color(0xFF8D79A6)]),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [BoxShadow(color: Color(0x66391A56),
                        blurRadius: 5, offset: Offset(0, 4))],
                  ),
                  child: Center(child: unlocked
                      ? Text('$level', style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900,
                          fontSize: 20, shadows: [Shadow(
                              color: Color(0xAA5D1F79), blurRadius: 3,
                              offset: Offset(1, 2))]))
                      : const Icon(Icons.lock_rounded, color: Colors.white, size: 18)),
                )),
                const SizedBox(height: 3),
                Text(stars == 0 ? '☆☆☆' : '${List.filled(stars, '★').join()}${List.filled(3 - stars, '☆').join()}',
                    style: TextStyle(fontSize: 12,
                        color: unlocked ? const Color(0xFFFFCF33) :
                            const Color(0xFFC5B6CB),
                        fontWeight: FontWeight.w900)),
              ]),
            );
          },
        ),
      ),
    ]);
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
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('BÖLÜM ${g.level}', style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w900,
                    letterSpacing: 1.6, color: Color(0xFF77328B))),
                Text(g.plan.name, maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF8439A3))),
              ])),
              _roundIcon(Icons.help_outline_rounded, _howToPlay),
              const SizedBox(width: 6),
              _roundIcon(_sound ? Icons.volume_up_rounded :
                  Icons.volume_off_rounded,
                  () { setState(() => _sound = !_sound); _save(); }),
            ]),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 17),
            padding: EdgeInsets.symmetric(horizontal: 13,
                vertical: compact ? 7 : 12),
            decoration: BoxDecoration(
              color: const Color(0xEDFFFFFF),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Color(0x309D359E),
                  blurRadius: 12, offset: Offset(0, 5))],
            ),
            child: Row(children: [
              Container(width: 69, height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFFFFB743), Color(0xFFFF7542)]),
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
                      backgroundColor: const Color(0xFFF4DDF6),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFB77A7)),
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
          _gameBoard(side),
          Column(children: [
            Text(_power == PowerMode.none ? _message :
                    'Patlatmak istediğin şekere dokun!',
                textAlign: TextAlign.center,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w900,
                    fontSize: compact ? 12 : 15,
                    color: const Color(0xFF85328C),
                    shadows: const [Shadow(color: Colors.white,
                        blurRadius: 5)])),
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
          Padding(padding: const EdgeInsets.only(bottom: 10),
            child: Text('Üç şekeri eşleştir • Kombolarla puan kazan',
                style: TextStyle(fontSize: compact ? 10 : 11,
                    color: const Color(0xFF84478E),
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        if (_result != null) Positioned.fill(child: _resultOverlay(g)),
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
        color: const Color(0xFF7D3BBB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE58B), width: 6),
        boxShadow: const [
          BoxShadow(color: Color(0x99902599), blurRadius: 16, offset: Offset(0, 9)),
          BoxShadow(color: Color(0x99FFFFFF), blurRadius: 3,
              offset: Offset(0, -2)),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(15),
        child: Stack(children: [
          ...[for (var r = 0; r < gridSize; r++)
            for (var c = 0; c < gridSize; c++)
              Positioned(left: inset + c * cell, top: inset + r * cell,
                width: cell, height: cell,
                child: Container(
                  margin: const EdgeInsets.all(.7),
                  decoration: BoxDecoration(
                    color: (r + c).isEven
                        ? const Color(0xFFB987E0)
                        : const Color(0xFFAC76D7),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0x227343AD)),
                  ),
                ),
              ),
          ],
          if (_selected != null && !_busy)
            Positioned(left: inset + _selected!.col * cell,
                top: inset + _selected!.row * cell,
                width: cell, height: cell,
                child: Container(decoration: BoxDecoration(
                  color: const Color(0x55FFFFFF),
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: const [BoxShadow(color: Color(0xAAFFFFFF),
                      blurRadius: 8)],
                )),
            ),
          ...[for (var r = 0; r < gridSize; r++)
            for (var c = 0; c < gridSize; c++)
              if (g.board[r][c] != null)
                AnimatedPositioned(
                  key: ValueKey('candy-${g.board[r][c]!.id}'),
                  duration: const Duration(milliseconds: 205),
                  curve: Curves.easeOutCubic,
                  left: inset + c * cell, top: inset + r * cell,
                  width: cell, height: cell,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    scale: _vanishing.contains(g.board[r][c]!.id) ? 0 :
                        (_newborn.contains(g.board[r][c]!.id) ? .80 : 1),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 170),
                      opacity: _vanishing.contains(g.board[r][c]!.id) ? 0 : 1,
                      child: Center(child: CandyPiece(
                        type: g.board[r][c]!.type,
                        size: cell * .91,
                      )),
                    ),
                  ),
                ),
          ],
          IgnorePointer(child: AnimatedBuilder(
            animation: _burstAnimation,
            builder: (context, child) => CustomPaint(
              size: Size.square(side),
              painter: SparklePainter(
                progress: _burstAnimation.value,
                centers: _burstPositions,
                colors: _burstColors.isEmpty ? [Colors.white] : _burstColors,
              ),
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
                    colors: [Color.lerp(color, Colors.white, .26)!, color]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: active
                    ? const Color(0xFFFFFF58) : Colors.white,
                    width: active ? 4 : 2),
                boxShadow: const [BoxShadow(color: Color(0x559E4093),
                    blurRadius: 7, offset: Offset(0, 4))],
              ),
              child: Icon(icon, color: Colors.white, size: 31,
                shadows: const [Shadow(color: Color(0x555C206F),
                    blurRadius: 3, offset: Offset(0, 2))]),
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
          Text(label, style: const TextStyle(fontSize: 10,
              fontWeight: FontWeight.w900, color: Color(0xFF763781))),
        ]),
      ),
    );
  }

  Widget _resultOverlay(MatchEngine g) {
    final win = _result == true;
    final isLast = g.level == 60;
    return Container(
      color: const Color(0xBB3D1D62),
      child: Center(child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 27),
        padding: const EdgeInsets.fromLTRB(18, 23, 18, 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xFFFFE2F4)]),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFFFD46A), width: 5),
          boxShadow: const [BoxShadow(color: Color(0x994B145E),
              blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(win ? 'TEBRİKLER!' : 'TEKRAR DENE',
              textAlign: TextAlign.center,
              style: _titleStyle(34, win ? const Color(0xFFE43E90) :
                  const Color(0xFF9257AE))),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => Icon(Icons.star_rounded,
                color: win && i < g.stars
                    ? const Color(0xFFFFB51C)
                    : const Color(0xFFD5C8DA), size: 66)),
          ),
          const SizedBox(height: 4),
          Text(win ? '${g.level}. bölümü tamamladın!' :
              'Hedefe ulaşmak için yeniden oyna!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF884595),
                  fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text('${g.score} PUAN', style: _titleStyle(
              26, const Color(0xFFFF9632))),
          const SizedBox(height: 22),
          _bigButton(win ? (isLast ? 'HARİTA' : 'SONRAKİ BÖLÜM')
              : 'YENİDEN DENE', () {
            if (win && isLast) {
              setState(() { _result = null; _page = ViewPage.map; });
            } else {
              _openGame(win ? g.level + 1 : g.level);
            }
          }, small: true),
          const SizedBox(height: 12),
          TextButton(onPressed: () => setState(() {
              _result = null; _page = ViewPage.map;
            }),
            child: const Text('Bölüm haritasına dön',
                style: TextStyle(color: Color(0xFF9954AD),
                    fontWeight: FontWeight.w800)),
          ),
        ]),
      )),
    );
  }

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
      decoration: BoxDecoration(color: const Color(0xF0FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x329D45A5), blurRadius: 6,
              offset: Offset(0, 3))]),
      child: Icon(icon, color: const Color(0xFF9A3FC0), size: 24),
    ),
  );

  Widget _pill(String text, Color shade) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xEFFFFFFF),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Text(text, style: TextStyle(color: shade,
        fontSize: 12, fontWeight: FontWeight.w900)),
  );

  Widget _bigButton(String label, VoidCallback action,
      {bool small = false,
       Color colorA = const Color(0xFFFFB83C),
       Color colorB = const Color(0xFFFF653D)}) {
    return GestureDetector(
      onTap: action,
      child: Container(
        width: small ? 250 : 285,
        height: small ? 57 : 74,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter,
              end: Alignment.bottomCenter, colors: [colorA, colorB]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFF1C8), width: 3),
          boxShadow: [
            BoxShadow(color: colorB.withValues(alpha: .45), blurRadius: 8,
                offset: const Offset(0, 7)),
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
