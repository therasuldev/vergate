import '../core/app_version.dart';
import '../core/json_utils.dart';

/// Version rules and store link for a single platform.
class VergatePlatformConfig {
  /// Creates a platform configuration.
  const VergatePlatformConfig({
    this.minVersion,
    this.latestVersion,
    this.storeUrl,
  });

  /// Creates a configuration from a decoded JSON map.
  ///
  /// Expected keys: `min_version`, `latest_version`, `store_url`.
  /// Invalid or missing values become `null`.
  factory VergatePlatformConfig.fromJson(Map<String, dynamic> json) {
    return VergatePlatformConfig(
      minVersion: AppVersion.tryParse(asNonEmptyString(json['min_version'])),
      latestVersion: AppVersion.tryParse(
        asNonEmptyString(json['latest_version']),
      ),
      storeUrl: asNonEmptyString(json['store_url']),
    );
  }

  /// The lowest version allowed to run. Older versions get a forced update.
  final AppVersion? minVersion;

  /// The newest published version. Older versions get an optional update.
  final AppVersion? latestVersion;

  /// Store page opened when the user taps the update button.
  final String? storeUrl;

  /// Converts this configuration back to JSON.
  Map<String, dynamic> toJson() => {
    if (minVersion != null) 'min_version': minVersion.toString(),
    if (latestVersion != null) 'latest_version': latestVersion.toString(),
    if (storeUrl != null) 'store_url': storeUrl,
  };
}
