import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vergate/vergate.dart';

const _storeUrl = 'https://store.example/app';

/// Installed version in these tests is 1.3.0.
const _forceConfig = VergateConfig(
  android: VergatePlatformConfig(
    minVersion: AppVersion(1, 3, 5),
    latestVersion: AppVersion(1, 4, 0),
    storeUrl: _storeUrl,
  ),
  releaseNotes: ['Faster loading'],
);

const _softConfig = VergateConfig(
  android: VergatePlatformConfig(
    minVersion: AppVersion(1),
    latestVersion: AppVersion(1, 4, 0),
    storeUrl: _storeUrl,
  ),
);

VergateController _controller(VergateConfig config, {List<Uri>? openedUrls}) {
  final controller = VergateController(
    source: CallbackSource(() async => config),
    platform: VergatePlatform.android,
    versionProvider: () async => AppVersion.parse('1.3.0'),
    storage: MemoryStorage(),
    urlOpener: (url) async {
      openedUrls?.add(url);
      return true;
    },
  );
  addTearDown(controller.dispose);
  return controller;
}

Widget _app(
  VergateController controller, {
  VoidCallback? onHomeTap,
  VergateSoftUpdateStyle style = VergateSoftUpdateStyle.banner,
  VergateStatusBuilder<VergateForceUpdate>? forceBuilder,
}) {
  return MaterialApp(
    builder: (context, child) => VergateGate(
      controller: controller,
      softUpdateStyle: style,
      forceUpdateBuilder: forceBuilder,
      child: child!,
    ),
    home: Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: onHomeTap ?? () {},
          child: const Text('Home'),
        ),
      ),
    ),
  );
}

void main() {
  group('VergateGate', () {
    testWidgets('shows only the app when up to date', (tester) async {
      var taps = 0;
      final controller = _controller(const VergateConfig());
      await tester.pumpWidget(_app(controller, onHomeTap: () => taps++));

      await controller.check();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'));
      expect(taps, 1);
      expect(find.text('Update Now'), findsNothing);
    });

    testWidgets('force update blocks the app and cannot be dismissed', (
      tester,
    ) async {
      var taps = 0;
      final opened = <Uri>[];
      final controller = _controller(_forceConfig, openedUrls: opened);
      await tester.pumpWidget(_app(controller, onHomeTap: () => taps++));

      await controller.check();
      await tester.pumpAndSettle();

      expect(find.text('Update Now'), findsOneWidget);
      expect(find.text('Faster loading'), findsOneWidget);
      expect(find.text('Remind me later'), findsNothing);

      // The app underneath must not receive taps.
      await tester.tap(find.text('Home'), warnIfMissed: false);
      expect(taps, 0);

      await tester.tap(find.text('Update Now'));
      await tester.pump();
      expect(opened, [Uri.parse(_storeUrl)]);
    });

    testWidgets('soft update banner can be dismissed (snoozed)', (
      tester,
    ) async {
      final controller = _controller(_softConfig);
      await tester.pumpWidget(_app(controller));

      await controller.check();
      await tester.pumpAndSettle();
      expect(find.text('New version available'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('New version available'), findsNothing);
      expect(controller.status, isA<VergateUpToDate>());
    });

    testWidgets('stringsBuilder provides localized texts', (tester) async {
      final controller = _controller(_forceConfig);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => VergateGate(
            controller: controller,
            stringsBuilder: (context) => const VergateStrings(
              updateTitle: 'إصدار جديد متاح',
              updateNow: 'حدّث الآن',
            ),
            child: child!,
          ),
          home: const Scaffold(body: SizedBox()),
        ),
      );

      await controller.check();
      await tester.pumpAndSettle();

      expect(find.text('إصدار جديد متاح'), findsOneWidget);
      expect(find.text('حدّث الآن'), findsOneWidget);
    });

    testWidgets('soft update dialog offers skip', (tester) async {
      final controller = _controller(_softConfig);
      await tester.pumpWidget(
        _app(controller, style: VergateSoftUpdateStyle.dialog),
      );

      await controller.check();
      await tester.pumpAndSettle();
      expect(find.text('Remind me later'), findsOneWidget);

      await tester.tap(find.text('Skip this version'));
      await tester.pumpAndSettle();

      expect(find.text('Update Now'), findsNothing);
      expect(controller.status, isA<VergateUpToDate>());
    });

    testWidgets('maintenance screen shows message and countdown', (
      tester,
    ) async {
      final controller = _controller(
        VergateConfig(
          maintenance: VergateMaintenance(
            enabled: true,
            until: DateTime.now().toUtc().add(const Duration(hours: 2)),
            message: 'Back soon',
          ),
        ),
      );
      await tester.pumpWidget(_app(controller));

      await controller.check();
      // No pumpAndSettle: the countdown timer keeps ticking.
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Back soon'), findsOneWidget);
      expect(find.text('Estimated time remaining'), findsOneWidget);

      // Dispose the tree so the countdown timer is cancelled.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('custom builder replaces the built-in force update', (
      tester,
    ) async {
      final controller = _controller(_forceConfig);
      await tester.pumpWidget(
        _app(
          controller,
          forceBuilder: (context, status, controller) =>
              const Center(child: Text('My own screen')),
        ),
      );

      await controller.check();
      await tester.pumpAndSettle();

      expect(find.text('My own screen'), findsOneWidget);
      expect(find.text('Update Now'), findsNothing);
    });
  });
}
