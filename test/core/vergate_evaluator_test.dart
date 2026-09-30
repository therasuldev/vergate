import 'package:flutter_test/flutter_test.dart';
import 'package:vergate/vergate.dart';

void main() {
  const androidRules = VergatePlatformConfig(
    minVersion: AppVersion(1, 2, 0),
    latestVersion: AppVersion(1, 4, 0),
    storeUrl: 'https://store.example/app',
  );
  const config = VergateConfig(
    android: androidRules,
    releaseNotes: ['Faster loading'],
  );

  VergateStatus run(String version, {VergateConfig cfg = config, DateTime? now}) {
    return VergateEvaluator.evaluate(
      config: cfg,
      currentVersion: AppVersion.parse(version),
      platform: VergatePlatform.android,
      now: now,
    );
  }

  group('update rules', () {
    test('below min_version forces update', () {
      final status = run('1.1.9');
      expect(status, isA<VergateForceUpdate>());
      expect((status as VergateForceUpdate).storeUrl, 'https://store.example/app');
      expect(status.releaseNotes, ['Faster loading']);
    });

    test('between min and latest is a soft update', () {
      expect(run('1.3.0'), isA<VergateSoftUpdate>());
    });

    test('at latest version is up to date', () {
      expect(run('1.4.0'), isA<VergateUpToDate>());
    });

    test('newer than latest is up to date', () {
      expect(run('2.0.0'), isA<VergateUpToDate>());
    });

    test('missing platform rules never block', () {
      final status = VergateEvaluator.evaluate(
        config: config,
        currentVersion: AppVersion.parse('0.0.1'),
        platform: VergatePlatform.ios,
      );
      expect(status, isA<VergateUpToDate>());
    });
  });

  group('maintenance', () {
    final from = DateTime.utc(2026, 10, 1, 22);
    final until = DateTime.utc(2026, 10, 2, 2);
    final cfg = VergateConfig(
      android: androidRules,
      maintenance: VergateMaintenance(enabled: true, from: from, until: until),
    );

    test('is active inside the window and beats force update', () {
      final status = run('1.0.0', cfg: cfg, now: DateTime.utc(2026, 10, 2));
      expect(status, isA<VergateUnderMaintenance>());
    });

    test('is ignored outside the window', () {
      final status = run('1.4.0', cfg: cfg, now: DateTime.utc(2026, 10, 3));
      expect(status, isA<VergateUpToDate>());
    });

    test('is ignored when disabled', () {
      const off = VergateMaintenance(enabled: false);
      expect(off.isActiveAt(DateTime.now()), isFalse);
    });

    test('open-ended window stays active', () {
      const open = VergateMaintenance(enabled: true);
      expect(open.isActiveAt(DateTime.utc(2030)), isTrue);
    });
  });

  group('VergateConfig JSON', () {
    test('parses a full config string', () {
      final parsed = VergateConfig.fromJsonString('''
      {
        "android": {"min_version": "1.2.0", "latest_version": "1.4.0",
                    "store_url": "https://play.google.com/x"},
        "ios": {"min_version": "1.1.0"},
        "release_notes": ["A", "B", 3],
        "maintenance": {"enabled": true, "until": "2026-10-02T02:00:00Z",
                        "message": "Back soon"}
      }''');

      expect(parsed.android!.minVersion, const AppVersion(1, 2, 0));
      expect(parsed.ios!.latestVersion, isNull);
      expect(parsed.releaseNotes, ['A', 'B']);
      expect(parsed.maintenance!.enabled, isTrue);
      expect(parsed.maintenance!.message, 'Back soon');
    });

    test('ignores invalid versions instead of throwing', () {
      final parsed = VergateConfig.fromJson({
        'android': {'min_version': 'oops', 'latest_version': '1.0.0'},
      });
      expect(parsed.android!.minVersion, isNull);
      expect(parsed.android!.latestVersion, const AppVersion(1));
    });

    test('non-object JSON throws FormatException', () {
      expect(() => VergateConfig.fromJsonString('[1, 2]'), throwsFormatException);
    });
  });
}