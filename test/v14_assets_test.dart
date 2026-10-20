import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('V14 illustasyon dosyalari kayitli ve okunabilir', () async {
    for (final asset in <String>[
      'assets/images/v14_logo.webp',
      'assets/images/v14_shop_header.webp',
      'assets/images/v14_daily_header.webp',
      'assets/images/v14_hammer.webp',
      'assets/images/v14_line.webp',
      'assets/images/v14_shuffle.webp',
      'assets/images/v14_hearts.webp',
      'assets/images/v14_bomb.webp',
      'assets/images/v14_crown.webp',
    ]) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(100));
    }
  });
}
