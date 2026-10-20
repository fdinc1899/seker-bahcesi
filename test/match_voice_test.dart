import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/match_voice.dart';

void main() {
  test('3, 4 and 5+ matching candies have Turkish voice callouts', () {
    expect(celebrationPhraseForMatch(3), 'Harika!');
    expect(celebrationPhraseForMatch(4), 'Mükemmel!');
    expect(celebrationPhraseForMatch(5), 'Muhteşem!');
    expect(celebrationPhraseForMatch(8), 'Muhteşem!');
    expect(celebrationPhraseForMatch(0), isNull);
  });
  test('cascade without a conventional match says super combo', () {
    expect(celebrationPhraseForMatch(2, chain: 2), 'Süper kombo!');
  });
}
