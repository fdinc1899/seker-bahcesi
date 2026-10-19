/// V9 offline wheel and permanent color collection.
/// Stored under `v9Rewards`, isolated from all older save keys.
String v9DayKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

const v9CollectionColorNames = <String>[
  'Mavi', 'Pembe', 'Yeşil', 'Sarı', 'Turuncu', 'Mor',
];
const v9CollectionGoal = 45;
const v9CollectionRewardCoins = 100;

class V9WheelReward {
  const V9WheelReward(this.name,
      {this.coins = 0, this.hammers = 0, this.lines = 0, this.shuffles = 0});
  final String name;
  final int coins;
  final int hammers;
  final int lines;
  final int shuffles;
}

const v9WheelRewards = <V9WheelReward>[
  V9WheelReward('50 Şeker Parası', coins: 50),
  V9WheelReward('1 Çekiç', hammers: 1),
  V9WheelReward('100 Şeker Parası', coins: 100),
  V9WheelReward('1 Karıştırma', shuffles: 1),
  V9WheelReward('150 Şeker Parası', coins: 150),
  V9WheelReward('1 Satır Patlatma', lines: 1),
];

class V9RewardsProgress {
  V9RewardsProgress({required DateTime today}) : day = v9DayKey(today);

  String day;
  int? wheelIndex;
  int totalSpins = 0;
  final List<int> colorCounts = List<int>.filled(6, 0);
  final Set<int> collectionClaims = <int>{};

  void advance(DateTime now) {
    final key = v9DayKey(now);
    if (key == day) return;
    day = key;
    wheelIndex = null;
  }

  bool canSpin(DateTime now) {
    advance(now);
    return wheelIndex == null;
  }

  /// Consumes the free spin synchronously BEFORE any wheel animation begins.
  /// The UI also awards the prize immediately, preventing duplicate taps.
  V9WheelReward? spin(int index, DateTime now) {
    if (index < 0 || index >= v9WheelRewards.length || !canSpin(now)) {
      return null;
    }
    wheelIndex = index;
    totalSpins = (totalSpins + 1).clamp(0, 100000).toInt();
    return v9WheelRewards[index];
  }

  /// Called only for candy cells that are cleared in a real match wave.
  void recordWave(Iterable<int> candyTypes) {
    for (final type in candyTypes) {
      if (type >= 0 && type < colorCounts.length) {
        colorCounts[type] = (colorCounts[type] + 1).clamp(0, 1000000).toInt();
      }
    }
  }

  bool canClaimColor(int type) => type >= 0 &&
      type < colorCounts.length &&
      colorCounts[type] >= v9CollectionGoal &&
      !collectionClaims.contains(type);

  int? claimColor(int type) {
    if (!canClaimColor(type)) return null;
    collectionClaims.add(type);
    return v9CollectionRewardCoins;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'day': day,
    'wheelIndex': wheelIndex,
    'totalSpins': totalSpins,
    'colors': List<int>.from(colorCounts),
    'collectionClaims': collectionClaims.toList()..sort(),
  };

  factory V9RewardsProgress.fromJson(Map<String, dynamic> data, DateTime now) {
    final state = V9RewardsProgress(today: now);
    // Only today's spin can block today's free prize.
    if (data['day'] == state.day) {
      final i = data['wheelIndex'];
      if (i is int && i >= 0 && i < v9WheelRewards.length) {
        state.wheelIndex = i;
      }
    }
    final total = data['totalSpins'];
    if (total is int) state.totalSpins = total.clamp(0, 100000).toInt();
    final counts = data['colors'];
    if (counts is List) {
      for (var i = 0; i < state.colorCounts.length && i < counts.length; i++) {
        final count = counts[i];
        if (count is int) state.colorCounts[i] = count.clamp(0, 1000000).toInt();
      }
    }
    final claimed = data['collectionClaims'];
    if (claimed is List) {
      state.collectionClaims.addAll(claimed.whereType<int>()
          .where((i) => i >= 0 && i < state.colorCounts.length));
    }
    return state;
  }
}
