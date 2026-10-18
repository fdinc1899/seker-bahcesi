/// Offline daily gifts & missions. Stored in its own SharedPreferences key;
/// pre-existing player progress keys are unchanged.
class DailyGift {
  const DailyGift({this.hammers = 0, this.lines = 0, this.shuffles = 0});
  final int hammers;
  final int lines;
  final int shuffles;

  String get description {
    final parts = <String>[
      if (hammers > 0) '+$hammers Çekiç',
      if (lines > 0) '+$lines Satır',
      if (shuffles > 0) '+$shuffles Karıştır',
    ];
    return parts.join(' • ');
  }
}

String localDay(DateTime now) =>
    '${now.year.toString().padLeft(4, '0')}-'
    '${now.month.toString().padLeft(2, '0')}-'
    '${now.day.toString().padLeft(2, '0')}';

/// `day` is the date for mission counters, `claimedDay` for the login gift.
/// These must be distinct so opening after midnight never grants a gift.
class DailyProgress {
  DailyProgress({
    required this.day,
    this.claimedDay = '',
    this.streak = 0,
    this.matches = 0,
    this.specials = 0,
    this.wins = 0,
    Set<int>? rewarded,
  }) : rewarded = rewarded ?? <int>{};

  String day;
  String claimedDay;
  int streak;
  int matches;
  int specials;
  int wins;
  final Set<int> rewarded;

  factory DailyProgress.fresh(DateTime now) => DailyProgress(day: localDay(now));

  factory DailyProgress.fromJson(Map<String, dynamic> data, DateTime now) {
    final model = DailyProgress(
      day: data['day'] as String? ?? localDay(now),
      claimedDay: data['claimedDay'] as String? ?? '',
      streak: (data['streak'] as num?)?.toInt() ?? 0,
      matches: (data['matches'] as num?)?.toInt() ?? 0,
      specials: (data['specials'] as num?)?.toInt() ?? 0,
      wins: (data['wins'] as num?)?.toInt() ?? 0,
      rewarded: (data['rewarded'] as List<dynamic>? ?? [])
          .whereType<num>().map((e) => e.toInt()).where((i) => i >= 0 && i < 3).toSet(),
    );
    model.advance(now);
    return model;
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'claimedDay': claimedDay,
    'streak': streak,
    'matches': matches,
    'specials': specials,
    'wins': wins,
    'rewarded': rewarded.toList()..sort(),
  };

  /// Reset missions when the player's local calendar date changes.
  void advance(DateTime now) {
    final today = localDay(now);
    if (day == today) return;
    day = today;
    matches = 0;
    specials = 0;
    wins = 0;
    rewarded.clear();
  }

  bool canClaim(DateTime now) => claimedDay != localDay(now);

  /// Returns no reward for repeated claims on the same calendar day.
  DailyGift? claim(DateTime now) {
    advance(now);
    if (!canClaim(now)) return null;
    final previous = DateTime.tryParse(claimedDay);
    final date = DateTime(now.year, now.month, now.day);
    final yesterday = date.subtract(const Duration(days: 1));
    streak = previous != null &&
            previous.year == yesterday.year &&
            previous.month == yesterday.month &&
            previous.day == yesterday.day
        ? streak + 1
        : 1;
    claimedDay = localDay(now);
    // A 7 day cycle; no paid currency or internet required.
    switch ((streak - 1) % 7) {
      case 0: return const DailyGift(hammers: 1);
      case 1: return const DailyGift(lines: 1);
      case 2: return const DailyGift(shuffles: 1);
      case 3: return const DailyGift(hammers: 2);
      case 4: return const DailyGift(lines: 2);
      case 5: return const DailyGift(shuffles: 2);
      default: return const DailyGift(hammers: 1, lines: 1, shuffles: 1);
    }
  }

  void registerMatch(DateTime now) { advance(now); matches++; }
  void registerSpecial(DateTime now, int count) {
    advance(now);
    if (count > 0) specials += count;
  }
  void registerWin(DateTime now) { advance(now); wins++; }

  int progress(int task) => switch (task) {
    0 => matches,
    1 => specials,
    _ => wins,
  };

  int goal(int task) => switch (task) {
    0 => 5,
    1 => 2,
    _ => 1,
  };

  String title(int task) => switch (task) {
    0 => '5 eşleşme yap',
    1 => '2 özel şeker oluştur',
    _ => '1 bölüm kazan',
  };

  bool canCollectMission(int task) => task >= 0 && task < 3 &&
      !rewarded.contains(task) && progress(task) >= goal(task);

  DailyGift? collectMission(int task) {
    if (!canCollectMission(task)) return null;
    rewarded.add(task);
    return switch (task) {
      0 => const DailyGift(hammers: 1),
      1 => const DailyGift(lines: 1),
      _ => const DailyGift(shuffles: 1),
    };
  }
}
