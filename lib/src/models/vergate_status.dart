import '../core/app_version.dart';
import 'maintenance.dart';

/// The result of comparing the installed app against the remote config.
///
/// This is a sealed class, so a `switch` over it is checked for
/// exhaustiveness by the compiler:
/// ```dart
/// switch (status) {
///   case VergateUpToDate():
///   case VergateSoftUpdate():
///   case VergateForceUpdate():
///   case VergateUnderMaintenance():
/// }
/// ```
sealed class VergateStatus {
  const VergateStatus();
}

/// The app can be used normally.
final class VergateUpToDate extends VergateStatus {
  /// Creates an up-to-date status.
  const VergateUpToDate();
}

/// Base class for statuses where a newer version is available.
sealed class VergateUpdateStatus extends VergateStatus {
  /// Creates an update status.
  const VergateUpdateStatus({
    required this.currentVersion,
    this.latestVersion,
    this.storeUrl,
    this.releaseNotes = const [],
  });

  /// The version installed on this device.
  final AppVersion currentVersion;

  /// The newest published version, if known.
  final AppVersion? latestVersion;

  /// Store page to open for the update.
  final String? storeUrl;

  /// What is new in the latest version.
  final List<String> releaseNotes;
}

/// A newer version exists, but the user may continue with the current one.
final class VergateSoftUpdate extends VergateUpdateStatus {
  /// Creates a soft update status.
  const VergateSoftUpdate({
    required super.currentVersion,
    super.latestVersion,
    super.storeUrl,
    super.releaseNotes,
  });
}

/// The installed version is no longer supported and must be updated.
final class VergateForceUpdate extends VergateUpdateStatus {
  /// Creates a force update status.
  const VergateForceUpdate({
    required super.currentVersion,
    super.latestVersion,
    super.storeUrl,
    super.releaseNotes,
  });
}

/// The app is temporarily unavailable.
final class VergateUnderMaintenance extends VergateStatus {
  /// Creates a maintenance status.
  const VergateUnderMaintenance(this.maintenance);

  /// The active maintenance settings (message and end time).
  final VergateMaintenance maintenance;
}
