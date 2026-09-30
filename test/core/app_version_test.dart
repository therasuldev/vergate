import 'package:flutter_test/flutter_test.dart';
import 'package:vergate/vergate.dart';

void main() {
  group('AppVersion.parse', () {
    test('parses full semantic version', () {
      final v = AppVersion.parse('1.2.3');
      expect([v.major, v.minor, v.patch, v.build], [1, 2, 3, 0]);
    });

    test('fills missing parts with zero', () {
      expect(AppVersion.parse('2'), const AppVersion(2, 0, 0));
      expect(AppVersion.parse('2.5'), const AppVersion(2, 5, 0));
    });

    test('supports "v" prefix and build number', () {
      final v = AppVersion.parse('v1.0.4+17');
      expect([v.major, v.minor, v.patch, v.build], [1, 0, 4, 17]);
    });

    test('ignores pre-release suffix', () {
      expect(AppVersion.parse('1.2.3-beta.1'), const AppVersion(1, 2, 3));
    });

    test('tryParse returns null on invalid input', () {
      expect(AppVersion.tryParse('abc'), isNull);
      expect(AppVersion.tryParse(null), isNull);
    });

    test('parse throws FormatException on invalid input', () {
      expect(() => AppVersion.parse('1.x.3'), throwsFormatException);
    });
  });

  group('AppVersion comparison', () {
    test('compares numerically, not lexicographically', () {
      expect(AppVersion.parse('1.10.0') > AppVersion.parse('1.9.0'), isTrue);
    });

    test('build number breaks ties', () {
      expect(AppVersion.parse('1.0.0+2') > AppVersion.parse('1.0.0+1'), isTrue);
    });

    test('equal versions are equal', () {
      expect(AppVersion.parse('1.2'), AppVersion.parse('1.2.0'));
    });
  });
}
