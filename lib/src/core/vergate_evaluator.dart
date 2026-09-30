import '../models/vergate_config.dart';
import '../models/vergate_platform.dart';
import '../models/vergate_status.dart';
import 'app_version.dart';

/// Decides which [VergateStatus] applies for a given configuration.
///
/// This is a pure function of its inputs, so it is easy to unit test.
///
/// Priority (highest first):
/// 1. Maintenance
/// 2. Force update (`current < min_version`)
/// 3. Soft update (`current < latest_version`)
/// 4. Up to date
abstract final class VergateEvaluator {
  /// Evaluates [config] for the installed [currentVersion].
  ///
  /// [now] can be provided in tests; it defaults to the current time.
  static VergateStatus evaluate({
    required VergateConfig config,
    required AppVersion currentVersion,
    required VergatePlatform platform,
    DateTime? now,
  }) {
    final maintenance = config.maintenance;
    if (maintenance != null && maintenance.isActiveAt(now ?? DateTime.now())) {
      return VergateUnderMaintenance(maintenance);
    }

    final rules = config.forPlatform(platform);
    if (rules == null) return const VergateUpToDate();

    final min = rules.minVersion;
    if (min != null && currentVersion < min) {
      return VergateForceUpdate(
        currentVersion: currentVersion,
        latestVersion: rules.latestVersion ?? min,
        storeUrl: rules.storeUrl,
        releaseNotes: config.releaseNotes,
      );
    }

    final latest = rules.latestVersion;
    if (latest != null && currentVersion < latest) {
      return VergateSoftUpdate(
        currentVersion: currentVersion,
        latestVersion: latest,
        storeUrl: rules.storeUrl,
        releaseNotes: config.releaseNotes,
      );
    }

    return const VergateUpToDate();
  }
}
