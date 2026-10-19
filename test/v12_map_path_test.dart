import 'package:flutter_test/flutter_test.dart';
import 'package:seker_bahcesi/v12_map_path.dart';

void main() {
  test('V12 harita dugumleri sirali ve ekran sinirlarinda', () {
    const width = 340.0;
    var previousY = -1.0;
    for (var i = 0; i < 20; i++) {
      final point = V12PathGeometry.levelCenter(i, width);
      expect(point.dx, greaterThanOrEqualTo(62));
      expect(point.dx, lessThanOrEqualTo(width - 62));
      expect(point.dy, greaterThan(previousY));
      expect(point.dy, lessThan(V12PathGeometry.height - 25));
      previousY = point.dy;
    }
  });
}
