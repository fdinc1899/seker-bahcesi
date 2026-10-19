/// Local-only V7 weekly activity and achievement progress.
/// Match board, level stars, sound settings and V6 coins retain their old keys.
const int v7MaxLevel = 120;

String v7WeekKey(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  final monday = day.subtract(Duration(days: day.weekday - DateTime.monday));
  final m = monday.month.toString().padLeft(2, '0');
  final d = monday.day.toString().padLeft(2, '0');
  return '${monday.year}-$m-$d';
}

class V7Reward {
  const V7Reward({required this.coins, this.hammers = 0, this.shuffles = 0});
  final int coins;
  final int hammers;
  final int shuffles;
}

class V7WeeklyTier {
  const V7WeeklyTier(this.goal, this.reward);
  final int goal;
  final V7Reward reward;
}

const v7WeeklyTiers = <V7WeeklyTier>[
  V7WeeklyTier(2, V7Reward(coins: 60)),
  V7WeeklyTier(5, V7Reward(coins: 140, shuffles: 1)),
  V7WeeklyTier(10, V7Reward(coins: 300, hammers: 1)),
];

class V7Badge {
  const V7Badge(this.id, this.title, this.description, this.goal, this.reward);
  final String id;
  final String title;
  final String description;
  final int goal;
  final V7Reward reward;
}

const v7Badges = <V7Badge>[
  V7Badge('five_levels', 'Tatlı Başlangıç', '5 farklı bölümü bitir', 5,
      V7Reward(coins: 75)),
  V7Badge('thirty_stars', 'Yıldız Avcısı', 'Toplam 30 yıldız kazan', 30,
      V7Reward(coins: 120)),
  V7Badge('ten_perfect', 'Üç Yıldız Ustası', '10 bölümde 3 yıldız kazan', 10,
      V7Reward(coins: 160, shuffles: 1)),
  V7Badge('forty_levels', 'Dünya Gezgini', '40 farklı bölümü bitir', 40,
      V7Reward(coins: 260)),
  V7Badge('hundred_twenty_stars', 'Parlayan Koleksiyon', 'Toplam 120 yıldız kazan', 120,
      V7Reward(coins: 350, hammers: 1)),
  V7Badge('hundred_levels', 'Şeker Efsanesi', '100 farklı bölümü bitir', 100,
      V7Reward(coins: 500, shuffles: 2)),
];

int v7BadgeProgress(V7Badge badge, Map<int, int> stars) {
  final valid = stars.entries.where((e) =>
      e.key >= 1 && e.key <= v7MaxLevel && e.value > 0);
  switch (badge.id) {
    case 'five_levels':
    case 'forty_levels':
    case 'hundred_levels':
      return valid.length;
    case 'thirty_stars':
    case 'hundred_twenty_stars':
      return valid.fold<int>(0, (sum, e) => sum + e.value.clamp(0, 3).toInt());
    case 'ten_perfect':
      return valid.where((e) => e.value >= 3).length;
    default:
      return 0;
  }
}

class V7Progress {
  V7Progress({required DateTime today}) : week = v7WeekKey(today);

  String week;
  final Set<int> completedThisWeek = <int>{};
  final Set<int> claimedWeeklyTiers = <int>{};
  final Set<String> claimedBadges = <String>{};

  void advance(DateTime today) {
    final key = v7WeekKey(today);
    if (week != key) {
      week = key;
      completedThisWeek.clear();
      claimedWeeklyTiers.clear();
    }
  }

  bool recordWin(int level, DateTime today) {
    advance(today);
    if (level < 1 || level > v7MaxLevel) return false;
    return completedThisWeek.add(level);
  }

  bool canClaimWeekly(int index, DateTime today) {
    advance(today);
    return index >= 0 && index < v7WeeklyTiers.length &&
        completedThisWeek.length >= v7WeeklyTiers[index].goal &&
        !claimedWeeklyTiers.contains(index);
  }

  V7Reward? claimWeekly(int index, DateTime today) {
    if (!canClaimWeekly(index, today)) return null;
    claimedWeeklyTiers.add(index);
    return v7WeeklyTiers[index].reward;
  }

  bool canClaimBadge(V7Badge badge, Map<int, int> stars) =>
      !claimedBadges.contains(badge.id) &&
      v7BadgeProgress(badge, stars) >= badge.goal &&
      v7Badges.any((b) => b.id == badge.id);

  V7Reward? claimBadge(V7Badge badge, Map<int, int> stars) {
    if (!canClaimBadge(badge, stars)) return null;
    claimedBadges.add(badge.id);
    return badge.reward;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'week': week,
    'levels': completedThisWeek.toList()..sort(),
    'weeklyClaims': claimedWeeklyTiers.toList()..sort(),
    'badges': claimedBadges.toList()..sort(),
  };

  factory V7Progress.fromJson(Map<String, dynamic> json, DateTime today) {
    final state = V7Progress(today: today);
    final week = json['week'];
    // Old or damaged week data must not resurrect expired weekly rewards.
    if (week == state.week) {
      final levels = json['levels'];
      if (levels is List) {
        state.completedThisWeek.addAll(levels.whereType<num>()
            .where((e) => e.isFinite && e == e.toInt())
            .map((e) => e.toInt())
            .where((e) => e >= 1 && e <= v7MaxLevel));
      }
      final claims = json['weeklyClaims'];
      if (claims is List) {
        state.claimedWeeklyTiers.addAll(claims.whereType<int>()
            .where((e) => e >= 0 && e < v7WeeklyTiers.length));
      }
    }
    final badges = json['badges'];
    if (badges is List) {
      state.claimedBadges.addAll(badges.whereType<String>()
          .where((id) => v7Badges.any((badge) => badge.id == id)));
    }
    return state;
  }
}
