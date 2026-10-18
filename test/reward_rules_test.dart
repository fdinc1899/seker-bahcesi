import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/reward_rules.dart';

void main() {
  test('Uc yildiz ilk kez kazanildiginda bir karistir verir', () {
    expect(prizeForLevel(previousBest: 0, stars: 3).bonusShuffles, 1);
    expect(prizeForLevel(previousBest: 2, stars: 3).bonusShuffles, 1);
  });

  test('Tekrarlanan uc yildiz hakki ikinci kez verilmez', () {
    expect(prizeForLevel(previousBest: 3, stars: 3).bonusShuffles, 0);
    expect(prizeForLevel(previousBest: 3, stars: 2).bonusShuffles, 0);
  });

  test('Bir ve iki yildizda ilave guclendirici yok', () {
    expect(prizeForLevel(previousBest: 0, stars: 0).awarded, false);
    expect(prizeForLevel(previousBest: 0, stars: 1).awarded, false);
    expect(prizeForLevel(previousBest: 0, stars: 2).awarded, false);
  });
}
