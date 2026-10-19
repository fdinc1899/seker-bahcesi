import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/v12_backup.dart';

void main() {
  test('V12 yedeği tüm ilerleme ve ödül anahtarlarını korur', () {
    final sample = <String, Object?>{
      'unlocked': 22,
      'stars': '{"1":3,"2":2}',
      'hammers': 8,
      'lineBlasts': 4,
      'shuffles': 2,
      'sound': true,
      'session': '{"level":22}',
      'dailyProgressV2': '{"claimed":true}',
      'v6Progress': '{"coins":500}',
      'v7Progress': '{"week":1}',
      'v8Season': '{"month":10}',
      'v9Rewards': '{"claimed":false}',
    };
    final encoded = V12BackupCodec.encode(sample);
    final restored = V12BackupCodec.decode(encoded);
    expect(restored, sample);
    expect(restored['unlocked'], 22);
  });

  test('Bozuk, eksik veya sahte yedek reddedilir', () {
    expect(() => V12BackupCodec.decode('ABCD'), throwsFormatException);
    expect(() => V12BackupCodec.decode('SB12-Zm9v'), throwsFormatException);
    expect(() => V12BackupCodec.encode({'unlocked': -2}), throwsFormatException);
  });
}
