import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/daily_rewards.dart';

void main() {
  test('Ayni gun giris hediyesi iki kez alinmaz', () {
    final day = DateTime(2026, 10, 18, 10);
    final daily = DailyProgress.fresh(day);
    expect(daily.claim(day)?.hammers, 1);
    expect(daily.claim(day), isNull);
    expect(daily.streak, 1);
  });

  test('Ardisik gun hediyesi seriyi ilerletir; boslukta sifirlar', () {
    final d = DailyProgress.fresh(DateTime(2026, 10, 17));
    d.claim(DateTime(2026, 10, 17));
    expect(d.claim(DateTime(2026, 10, 18))?.lines, 1);
    expect(d.streak, 2);
    expect(d.claim(DateTime(2026, 10, 21))?.hammers, 1);
    expect(d.streak, 1);
  });

  test('Misyon odulleri yalnizca bir kez verilir ve ertesi gun sifirlanir', () {
    final d = DailyProgress.fresh(DateTime(2026, 10, 18));
    for (var i = 0; i < 5; i++) {
      d.registerMatch(DateTime(2026, 10, 18));
    }
    expect(d.canCollectMission(0), isTrue);
    expect(d.collectMission(0)?.hammers, 1);
    expect(d.collectMission(0), isNull);
    d.registerSpecial(DateTime(2026, 10, 18), 2);
    expect(d.collectMission(1)?.lines, 1);
    d.registerWin(DateTime(2026, 10, 18));
    expect(d.collectMission(2)?.shuffles, 1);
    d.advance(DateTime(2026, 10, 19));
    expect(d.progress(0), 0);
    expect(d.rewarded, isEmpty);
    expect(d.claimedDay, '');
  });

  test('Kayıttan geri yukleme eski ilerlemeyi korur', () {
    final now = DateTime(2026, 10, 18);
    final d = DailyProgress.fresh(now);
    d.registerMatch(now);
    d.claim(now);
    final loaded = DailyProgress.fromJson(d.toJson(), now);
    expect(loaded.matches, 1);
    expect(loaded.claim(now), isNull);
    expect(loaded.streak, 1);
  });
}
