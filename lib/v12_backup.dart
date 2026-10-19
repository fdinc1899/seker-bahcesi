import 'dart:convert';

/// Portable, human-copyable backup for local Şeker Bahçesi progress.
/// The code MUST be saved outside the app before an uninstall.
/// It contains only game progress, never account credentials.
class V12BackupCodec {
  static const intKeys = <String>{'unlocked', 'hammers', 'lineBlasts', 'shuffles'};
  static const boolKeys = <String>{'sound'};
  static const jsonKeys = <String>{
    'stars', 'dailyProgressV2', 'v6Progress', 'v7Progress',
    'v8Season', 'v9Rewards', 'session',
  };
  static const keys = <String>{
    ...intKeys, ...boolKeys, ...jsonKeys,
  };

  static void _validate(String name, Object? value) {
    if (!keys.contains(name)) {
      throw const FormatException('Bilinmeyen oyun kaydı.');
    }
    if (intKeys.contains(name)) {
      if (value is! int || value < 0 || value > 100000000) {
        throw const FormatException('Sayısal kayıt geçersiz.');
      }
      if (name == 'unlocked' && (value < 1 || value > 120)) {
        throw const FormatException('Bölüm kaydı geçersiz.');
      }
    } else if (boolKeys.contains(name)) {
      if (value is! bool) {
        throw const FormatException('Ses ayarı geçersiz.');
      }
    } else {
      if (value is! String || value.length > 200000) {
        throw const FormatException('Oyun kaydı geçersiz.');
      }
      final parsed = jsonDecode(value);
      if (parsed is! Map) {
        throw const FormatException('İlerleme verisi geçersiz.');
      }
    }
  }

  static String encode(Map<String, Object?> records) {
    final values = <String, Object>{};
    for (final item in records.entries) {
      if (item.value == null) continue;
      _validate(item.key, item.value);
      values[item.key] = item.value!;
    }
    return 'SB12-' + base64Url.encode(utf8.encode(jsonEncode({
      'app': 'SekerBahcesi', 'format': 12, 'progress': values,
    })));
  }

  static Map<String, Object> decode(String source) {
    try {
      final input = source.replaceAll(RegExp(r'\s+'), '');
      if (!input.startsWith('SB12-') || input.length > 500000) {
        throw const FormatException('Yedek kodunun başlığı hatalı.');
      }
      final bytes = base64Url.decode(base64Url.normalize(input.substring(5)));
      final parsed = jsonDecode(utf8.decode(bytes));
      if (parsed is! Map ||
          parsed['app'] != 'SekerBahcesi' || parsed['format'] != 12 ||
          parsed['progress'] is! Map) {
        throw const FormatException('Bu kod Şeker Bahçesi V12 yedeği değil.');
      }
      final raw = Map<String, dynamic>.from(parsed['progress'] as Map);
      if (!raw.containsKey('unlocked') || !raw.containsKey('stars')) {
        throw const FormatException('Yedek eksik; bölüm bilgisi bulunamadı.');
      }
      final result = <String, Object>{};
      for (final entry in raw.entries) {
        _validate(entry.key, entry.value);
        result[entry.key] = entry.value as Object;
      }
      return result;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Yedek kodu bozuk veya eksik.');
    }
  }
}
