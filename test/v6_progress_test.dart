import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/v6_progress.dart';

void main() {
  test('Six worlds cover exactly 120 levels without gaps', () {
    expect(v6Worlds.length, 6);
    expect(v6LevelCount, 120);
    for (var i = 0; i < v6Worlds.length; i++) {
      final world = v6Worlds[i];
      expect(world.start, i * 20 + 1);
      expect(world.end, (i + 1) * 20);
    }
  });

  test('V5 completed last level is unlocked for V6 without replay', () {
    expect(v6MigrateUnlocked(60, {60: 3}), 61);
    expect(v6MigrateUnlocked(60, {60: 0}), 60);
    expect(v6MigrateUnlocked(30, {20: 3}), 30);
    expect(v6MigrateUnlocked(70, {60: 3}), 70);
  });

  test('First clear awards coins, repeats cannot farm rewards', () {
    expect(v6CoinsForWin(previousBest: 0, stars: 1), 40);
    expect(v6CoinsForWin(previousBest: 0, stars: 3), 60);
    expect(v6CoinsForWin(previousBest: 3, stars: 3), 0);
    expect(v6CoinsForWin(previousBest: 1, stars: 3), 20);
    expect(v6CoinsForWin(previousBest: 3, stars: 2), 0);
  });

  test('A world chest is available only once after its last level', () {
    final progress = V6Progress();
    final stars = {20: 3, 40: 2};
    expect(progress.canClaimChest(19, stars), isFalse);
    expect(progress.canClaimChest(60, stars), isFalse);
    final prize = progress.claimChest(20, stars);
    expect(prize, isNotNull);
    expect(prize!.coins, 150);
    expect(prize.hammers, 1);
    expect(prize.shuffles, 1);
    expect(progress.coins, 150);
    expect(progress.claimChest(20, stars), isNull);
    expect(progress.coins, 150);
    expect(progress.canClaimChest(40, stars), isTrue);
  });

  test('Booster costs stay safe and cannot make balance negative', () {
    final progress = V6Progress(coins: 160);
    expect(progress.purchase(V6Booster.hammer), isTrue);
    expect(progress.coins, 85);
    expect(progress.purchase(V6Booster.line), isFalse);
    expect(progress.purchase(V6Booster.shuffle), isFalse);
    expect(progress.coins, 85);
  });

  test('V6 economy safely round-trips and ignores old missing keys', () {
    final progress = V6Progress(coins: 750, claimedChests: {20, 60});
    final restored = V6Progress.fromJson(progress.toJson());
    expect(restored.coins, 750);
    expect(restored.claimedChests, {20, 60});
    expect(V6Progress.fromJson({}).coins, 0);
    expect(V6Progress.fromJson({'coins': -15,
      'claimedChests': [19, 20, 20, 1000]}).claimedChests, {20});
  });
}
