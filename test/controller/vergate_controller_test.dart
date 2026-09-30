import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vergate/vergate.dart';

const _storeUrl = 'https://store.example/app';

/// Config where the installed 1.3.0 gets a soft update to [latest].
VergateConfig _soft([String latest = '1.4.0']) => VergateConfig(
  android: VergatePlatformConfig(
    minVersion: const AppVersion(1),
    latestVersion: AppVersion.parse(latest),
    storeUrl: _storeUrl,
  ),
);

/// Config where the installed 1.3.0 is below the minimum version.
VergateConfig _force() => const VergateConfig(
  android: VergatePlatformConfig(
    minVersion: AppVersion(1, 3, 5),
    latestVersion: AppVersion(1, 4, 0),
    storeUrl: _storeUrl,
  ),
);

/// Test harness with a controllable source, clock and storage.
class _Fixture {
  _Fixture(this.config);

  VergateConfig config;
  Object? failWith;
  int fetchCount = 0;
  DateTime now = DateTime.utc(2026, 10, 1, 12);

  final MemoryStorage storage = MemoryStorage();
  final List<Uri> openedUrls = [];
  final List<Object> errors = [];

  late final VergateController controller = build();

  /// Builds a controller sharing this fixture's storage and clock.
  VergateController build() {
    return VergateController(
      source: CallbackSource(() async {
        fetchCount++;
        if (failWith != null) throw failWith!;
        return config;
      }),
      platform: VergatePlatform.android,
      versionProvider: () async => AppVersion.parse('1.3.0'),
      storage: storage,
      urlOpener: (url) async {
        openedUrls.add(url);
        return true;
      },
      clock: () => now,
      resumeCheckInterval: const Duration(hours: 6),
      onError: (error, _) => errors.add(error),
    );
  }

  void advance(Duration duration) => now = now.add(duration);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('check', () {
    test('starts up to date and evaluates after the first check', () async {
      final f = _Fixture(_force());
      expect(f.controller.status, isA<VergateUpToDate>());
      expect(f.controller.hasChecked, isFalse);

      await f.controller.check();

      expect(f.controller.status, isA<VergateForceUpdate>());
      expect(f.controller.hasChecked, isTrue);
      expect(f.controller.currentVersion, const AppVersion(1, 3, 0));
    });

    test('fails open when the source throws', () async {
      final f = _Fixture(_force())..failWith = Exception('offline');

      await f.controller.check();

      expect(f.controller.status, isA<VergateUpToDate>());
      expect(f.controller.lastError, isNotNull);
      expect(f.errors, hasLength(1));
    });

    test('keeps the previous status when a later check fails', () async {
      final f = _Fixture(_force());
      await f.controller.check();

      f.failWith = Exception('offline');
      await f.controller.check();

      expect(f.controller.status, isA<VergateForceUpdate>());
      expect(f.controller.lastError, isNotNull);
    });

    test('concurrent checks share one request', () async {
      final f = _Fixture(_soft());

      await Future.wait([f.controller.check(), f.controller.check()]);

      expect(f.fetchCount, 1);
    });
  });

  group('snooze', () {
    test('hides a soft update until it expires', () async {
      final f = _Fixture(_soft());
      await f.controller.check();
      expect(f.controller.status, isA<VergateSoftUpdate>());

      await f.controller.snooze(const Duration(hours: 1));
      expect(f.controller.status, isA<VergateUpToDate>());

      f.advance(const Duration(hours: 2));
      expect(f.controller.status, isA<VergateSoftUpdate>());
    });

    test('never hides a force update', () async {
      final f = _Fixture(_force());
      await f.controller.check();

      await f.controller.snooze();

      expect(f.controller.status, isA<VergateForceUpdate>());
    });
  });

  group('skipVersion', () {
    test('hides that version but shows a newer one', () async {
      final f = _Fixture(_soft('1.4.0'));
      await f.controller.check();

      await f.controller.skipVersion();
      expect(f.controller.status, isA<VergateUpToDate>());

      f.config = _soft('1.5.0');
      await f.controller.check();
      expect(f.controller.status, isA<VergateSoftUpdate>());
    });

    test('is ignored when there is no soft update', () async {
      final f = _Fixture(_force());
      await f.controller.check();

      await f.controller.skipVersion();

      expect(f.controller.status, isA<VergateForceUpdate>());
    });

    test('choices survive a restart through storage', () async {
      final f = _Fixture(_soft());
      await f.controller.check();
      await f.controller.skipVersion();

      final restarted = f.build();
      await restarted.check();

      expect(restarted.status, isA<VergateUpToDate>());
    });

    test('resetUserChoices shows the update again', () async {
      final f = _Fixture(_soft());
      await f.controller.check();
      await f.controller.skipVersion();

      await f.controller.resetUserChoices();

      expect(f.controller.status, isA<VergateSoftUpdate>());
    });
  });

  group('app resume', () {
    test('does not fetch again when a soft status is fresh', () async {
      final f = _Fixture(_soft());
      await f.controller.check();

      f.advance(const Duration(minutes: 1));
      f.controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(f.fetchCount, 1);
    });

    test('fetches again when the data is stale', () async {
      final f = _Fixture(_soft());
      await f.controller.check();

      f.advance(const Duration(hours: 7));
      f.controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(f.fetchCount, 2);
    });

    test('always fetches while a blocking status is shown', () async {
      final f = _Fixture(_force());
      await f.controller.check();

      f.advance(const Duration(minutes: 1));
      f.controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(f.fetchCount, 2);
    });

    test('re-evaluates the cache so an expired snooze shows again', () async {
      final f = _Fixture(_soft());
      await f.controller.check();
      await f.controller.snooze(const Duration(hours: 1));
      expect(f.controller.status, isA<VergateUpToDate>());

      f.advance(const Duration(hours: 2));
      f.controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(f.fetchCount, 1);
      expect(f.controller.status, isA<VergateSoftUpdate>());
    });
  });

  group('openStore & debug override', () {
    test('opens the store url of the current update', () async {
      final f = _Fixture(_soft());
      await f.controller.check();

      final opened = await f.controller.openStore();

      expect(opened, isTrue);
      expect(f.openedUrls, [Uri.parse(_storeUrl)]);
    });

    test('returns false when there is nothing to open', () async {
      final f = _Fixture(const VergateConfig());
      await f.controller.check();

      expect(await f.controller.openStore(), isFalse);
      expect(f.openedUrls, isEmpty);
    });

    test('debug override replaces the status and can be cleared', () async {
      final f = _Fixture(const VergateConfig());
      await f.controller.check();

      f.controller.debugOverrideStatus(
        const VergateUnderMaintenance(VergateMaintenance(enabled: true)),
      );
      expect(f.controller.status, isA<VergateUnderMaintenance>());

      f.controller.debugOverrideStatus(null);
      expect(f.controller.status, isA<VergateUpToDate>());
    });
  });
}
