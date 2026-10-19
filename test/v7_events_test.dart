import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/v7_events.dart';

void main() {
  final sunday = DateTime(2026, 10, 18, 22, 59);
  final monday = DateTime(2026, 10, 19, 0, 1);

  test('Weekly dates start on Monday and reset Sunday night', () {
    expect(v7WeekKey(sunday), '2026-10-12');
    expect(v7WeekKey(monday), '2026-10-19');
    final event = V7Progress(today: sunday);
    event.recordWin(1, sunday);
    event.recordWin(2, sunday);
    expect(event.claimWeekly(0, sunday)?.coins, 60);
    event.advance(monday);
    expect(event.completedThisWeek, isEmpty);
    expect(event.claimedWeeklyTiers, isEmpty);
    expect(event.week, '2026-10-19');
  });

  test('Weekly rewards are earned by unique levels and cannot be duplicated', () {
    final event = V7Progress(today: monday);
    expect(event.recordWin(1, monday), isTrue);
    expect(event.recordWin(1, monday), isFalse);
    expect(event.canClaimWeekly(0, monday), isFalse);
    event.recordWin(2, monday);
    expect(event.claimWeekly(0, monday)?.coins, 60);
    expect(event.claimWeekly(0, monday), isNull);
    for (var level = 3; level <= 10; level++) {
      event.recordWin(level, monday);
    }
    expect(event.claimWeekly(1, monday)?.shuffles, 1);
    expect(event.claimWeekly(2, monday)?.hammers, 1);
  });

  test('Badges are based on real saved stars, and grant reward once', () {
    final event = V7Progress(today: monday);
    final stars = {1: 3, 2: 3, 3: 3, 4: 3, 5: 3};
    final first = v7Badges.first;
    expect(v7BadgeProgress(first, stars), 5);
    expect(event.claimBadge(first, stars)?.coins, 75);
    expect(event.claimBadge(first, stars), isNull);
    expect(v7BadgeProgress(v7Badges[2], stars), 5);
    expect(event.canClaimBadge(v7Badges[2], stars), isFalse);
  });

  test('Saved rewards and badges survive reload; older saves work', () {
    final event = V7Progress(today: monday);
    event.recordWin(21, monday);
    event.recordWin(22, monday);
    event.claimWeekly(0, monday);
    event.claimBadge(v7Badges.first, {for (var i = 1; i <= 5; i++) i: 1});
    final restored = V7Progress.fromJson(event.toJson(), monday);
    expect(restored.completedThisWeek, {21, 22});
    expect(restored.claimedWeeklyTiers, {0});
    expect(restored.claimedBadges, {'five_levels'});
    expect(V7Progress.fromJson({}, monday).completedThisWeek, isEmpty);
    expect(V7Progress.fromJson(event.toJson(), monday.add(const Duration(days: 7)))
      .claimedWeeklyTiers, isEmpty);
    expect(V7Progress.fromJson(event.toJson(), monday.add(const Duration(days: 7)))
      .claimedBadges, {'five_levels'});
  });

  test('Corrupted progress ignores unknown stages, badges and levels', () {
    final restored = V7Progress.fromJson({
      'week': v7WeekKey(monday),
      'levels': [-1, 0, 1, 1, 121, 2.1, '2'],
      'weeklyClaims': [-1, 0, 10, '1'],
      'badges': ['five_levels', 'unknown'],
    }, monday);
    expect(restored.completedThisWeek, {1});
    expect(restored.claimedWeeklyTiers, {0});
    expect(restored.claimedBadges, {'five_levels'});
  });
}
