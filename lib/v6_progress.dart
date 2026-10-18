/// V6 meta progression. No changes to the saved match board format.
/// All rewards are earned in gameplay; there are no paid purchases or ads.
const int v6LevelCount = 120;
const int v6LevelsPerWorld = 20;

class V6World {
  const V6World(this.name, this.subtitle, this.start, this.primary, this.accent);
  final String name;
  final String subtitle;
  final int start;
  /// Plain ARGB values keep this model independent of Flutter widgets.
  final int primary;
  final int accent;
  int get end => start + v6LevelsPerWorld - 1;
}

const v6Worlds = <V6World>[
  V6World('Pamuk Şeker Vadisi', 'Tatlı yolculuk başlıyor', 1, 0xFFEF659C, 0xFFC24CF2),
  V6World('Çikolata Ormanı', 'Engelleri kır, yıldızları topla', 21, 0xFF8D52CB, 0xFF57378F),
  V6World('Gökkuşağı Şehri', 'Özel şekerler seni bekliyor', 41, 0xFFFC7D5C, 0xFFE34998),
  V6World('Jöle Adaları', 'Yeni bölüm maceraları', 61, 0xFF48B7DA, 0xFF6165D8),
  V6World('Kristal Krallığı', 'Parlayan şekerlerin ülkesi', 81, 0xFF8D75DF, 0xFF3E83C4),
  V6World('Altın Şeker Sarayı', 'Son yıldızların peşinde', 101, 0xFFE7A646, 0xFFE85A77),
];

/// Players who completed level 60 before V6 should enter the new world
/// without having to replay the old final level.
int v6MigrateUnlocked(int unlocked, Map<int, int> stars) {
  final safe = unlocked.clamp(1, v6LevelCount).toInt();
  if (safe == 60 && (stars[60] ?? 0) > 0) return 61;
  return safe;
}

enum V6Booster { hammer, line, shuffle }

int v6BoosterPrice(V6Booster booster) => switch (booster) {
      V6Booster.hammer => 75,
      V6Booster.line => 115,
      V6Booster.shuffle => 90,
    };

/// Existing level stars determine the grant: a repeated win cannot farm coins.
/// Improvements grant only the new stars, with a one-off completion bonus.
int v6CoinsForWin({required int previousBest, required int stars}) {
  final old = previousBest.clamp(0, 3).toInt();
  final current = stars.clamp(0, 3).toInt();
  if (current <= old) return 0;
  return (old == 0 ? 30 : 0) + (current - old) * 10;
}

class V6ChestReward {
  const V6ChestReward({required this.coins, required this.hammers,
      required this.shuffles});
  final int coins;
  final int hammers;
  final int shuffles;
}

class V6Progress {
  V6Progress({this.coins = 0, Set<int>? claimedChests})
      : claimedChests = claimedChests ?? <int>{};

  int coins;
  final Set<int> claimedChests;

  bool canAfford(V6Booster booster) => coins >= v6BoosterPrice(booster);

  bool purchase(V6Booster booster) {
    if (!canAfford(booster)) return false;
    coins -= v6BoosterPrice(booster);
    return true;
  }

  bool canClaimChest(int level, Map<int, int> stars) =>
      level >= v6LevelsPerWorld && level <= v6LevelCount &&
      level % v6LevelsPerWorld == 0 &&
      (stars[level] ?? 0) > 0 && !claimedChests.contains(level);

  V6ChestReward? claimChest(int level, Map<int, int> stars) {
    if (!canClaimChest(level, stars)) return null;
    claimedChests.add(level);
    const prize = V6ChestReward(coins: 150, hammers: 1, shuffles: 1);
    coins += prize.coins;
    return prize;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'coins': coins,
    'claimedChests': claimedChests.toList()..sort(),
  };

  factory V6Progress.fromJson(Map<String, dynamic> json) {
    final count = json['coins'];
    final claimed = json['claimedChests'];
    return V6Progress(
      coins: count is num ? count.toInt().clamp(0, 100000000).toInt() : 0,
      claimedChests: claimed is List
          ? claimed.whereType<num>().map((e) => e.toInt()).where((level) =>
              level >= v6LevelsPerWorld && level <= v6LevelCount &&
              level % v6LevelsPerWorld == 0).toSet()
          : <int>{},
    );
  }
}
