import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('V15: premium artwork can be loaded without errors', () async {
    for (final name in <String>[
      'assets/images/v15_candy_world.webp',
      'assets/images/v15_logo_cutout.png',
      'assets/images/v15_shop_banner.png',
    ]) {
      final bytes = await rootBundle.load(name);
      expect(bytes.lengthInBytes, greaterThan(1000), reason: name);
    }
  });
}
