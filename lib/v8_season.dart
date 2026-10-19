/// V8 offline seasonal challenges. Independent of board/session/star saves.
/// Every season uses the device's local calendar month.
const v8ColorNames = <String>[
  'Mavi', 'Pembe', 'Yeşil', 'Sarı', 'Turuncu', 'Mor',
];

String v8SeasonKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

/// Seasonal target rotates monthly through the existing six candy colors.
int v8TargetType(DateTime date) =>
    ((date.year * 12 + date.month - 1) % v8ColorNames.length);

enum V8Mission { colorHunt, combos, levelWins }

class V8Reward {
  const V8Reward({required this.coins, this.hammers = 0, this.shuffles = 0});
  final int coins;
  final int hammers;
  final int shuffles;
}

class V8MissionPlan {
  const V8MissionPlan(this.mission, this.goal, this.reward);
  final V8Mission mission;
  final int goal;
  final V8Reward reward;
}

const v8Missions = <V8MissionPlan>[
  V8MissionPlan(V8Mission.colorHunt, 60, V8Reward(coins: 180)),
  V8MissionPlan(V8Mission.combos, 5, V8Reward(coins: 220, hammers: 1)),
  V8MissionPlan(V8Mission.levelWins, 8, V8Reward(coins: 350, shuffles: 2)),
];

class V8SeasonProgress {
  V8SeasonProgress({required DateTime today})
      : season = v8SeasonKey(today), targetType = v8TargetType(today);

  String season;
  int targetType;
  int collected = 0;
  int combos = 0;
  final Set<int> finishedLevels = <int>{};
  final Set<V8Mission> claimed = <V8Mission>{};

  void advance(DateTime today) {
    final newSeason = v8SeasonKey(today);
    if (season == newSeason) return;
    season = newSeason;
    targetType = v8TargetType(today);
    collected = 0;
    combos = 0;
    finishedLevels.clear();
    claimed.clear();
  }

  /// Called only after a valid board match wave has actually been resolved.
  void recordWave(Iterable<int> matchedTypes, int chain, DateTime today) {
    advance(today);
    collected = (collected + matchedTypes.where((type) => type == targetType).length)
        .clamp(0, 100000).toInt();
    if (chain >= 2) combos = (combos + 1).clamp(0, 100000).toInt();
  }

  /// Replaying a level during one season never adds a second unique win.
  void recordWin(int level, DateTime today) {
    advance(today);
    if (level >= 1 && level <= 120) finishedLevels.add(level);
  }

  int progressFor(V8Mission mission) => switch (mission) {
    V8Mission.colorHunt => collected,
    V8Mission.combos => combos,
    V8Mission.levelWins => finishedLevels.length,
  };

  bool canClaim(V8Mission mission, DateTime today) {
    advance(today);
    for (final plan in v8Missions) {
      if (plan.mission == mission) {
        return !claimed.contains(mission) && progressFor(mission) >= plan.goal;
      }
    }
    return false;
  }

  V8Reward? claim(V8Mission mission, DateTime today) {
    if (!canClaim(mission, today)) return null;
    claimed.add(mission);
    for (final plan in v8Missions) {
      if (plan.mission == mission) return plan.reward;
    }
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'season': season,
    'collected': collected,
    'combos': combos,
    'levels': finishedLevels.toList()..sort(),
    'claims': claimed.map((mission) => mission.name).toList()..sort(),
  };

  factory V8SeasonProgress.fromJson(Map<String, dynamic> json, DateTime today) {
    final value = V8SeasonProgress(today: today);
    if (json['season'] != value.season) return value;
    int safeCounter(Object? raw) {
      if (raw is! int) return 0;
      return raw.clamp(0, 100000).toInt();
    }
    value.collected = safeCounter(json['collected']);
    value.combos = safeCounter(json['combos']);
    final rawLevels = json['levels'];
    if (rawLevels is List) {
      value.finishedLevels.addAll(rawLevels.whereType<int>()
          .where((level) => level >= 1 && level <= 120));
    }
    final rawClaims = json['claims'];
    if (rawClaims is List) {
      for (final name in rawClaims.whereType<String>()) {
        for (final mission in V8Mission.values) {
          if (name == mission.name) value.claimed.add(mission);
        }
      }
    }
    return value;
  }
}
