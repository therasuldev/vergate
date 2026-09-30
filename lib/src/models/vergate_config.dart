import 'dart:convert';

import '../core/json_utils.dart';
import 'maintenance.dart';
import 'platform_config.dart';
import 'vergate_platform.dart';

/// The complete remote configuration read by Vergate.
///
/// Example JSON:
/// ```json
/// {
///   "android": {
///     "min_version": "1.2.0",
///     "latest_version": "1.4.0",
///     "store_url": "https://play.google.com/store/apps/details?id=com.app"
///   },
///   "ios": {
///     "min_version": "1.2.0",
///     "latest_version": "1.4.0",
///     "store_url": "https://apps.apple.com/app/id123456789"
///   },
///   "release_notes": ["Faster loading", "Bug fixes"],
///   "maintenance": {
///     "enabled": false,
///     "from": "2026-10-01T22:00:00Z",
///     "until": "2026-10-02T02:00:00Z",
///     "message": "We will be back soon."
///   }
/// }
/// ```
class VergateConfig {
  /// Creates a configuration.
  const VergateConfig({
    this.android,
    this.ios,
    this.releaseNotes = const [],
    this.maintenance,
  });

  /// Creates a configuration from a decoded JSON map.
  factory VergateConfig.fromJson(Map<String, dynamic> json) {
    final android = asJsonMap(json['android']);
    final ios = asJsonMap(json['ios']);
    final maintenance = asJsonMap(json['maintenance']);

    return VergateConfig(
      android: android == null ? null : VergatePlatformConfig.fromJson(android),
      ios: ios == null ? null : VergatePlatformConfig.fromJson(ios),
      releaseNotes: asStringList(json['release_notes']),
      maintenance: maintenance == null
          ? null
          : VergateMaintenance.fromJson(maintenance),
    );
  }

  /// Creates a configuration from a raw JSON string.
  ///
  /// This is the format stored in a single Firebase Remote Config parameter.
  /// Throws a [FormatException] if [source] is not a valid JSON object.
  factory VergateConfig.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    final map = asJsonMap(decoded);
    if (map == null) {
      throw FormatException('Vergate config must be a JSON object', source);
    }
    return VergateConfig.fromJson(map);
  }

  /// Rules for Android. `null` means no rules (never blocks).
  final VergatePlatformConfig? android;

  /// Rules for iOS. `null` means no rules (never blocks).
  final VergatePlatformConfig? ios;

  /// Bullet points describing what is new in the latest version.
  final List<String> releaseNotes;

  /// Maintenance mode settings. Applies to all platforms.
  final VergateMaintenance? maintenance;

  /// Returns the rules that apply to [platform], if any.
  VergatePlatformConfig? forPlatform(VergatePlatform platform) {
    switch (platform) {
      case VergatePlatform.android:
        return android;
      case VergatePlatform.ios:
        return ios;
      case VergatePlatform.other:
        return null;
    }
  }

  /// Converts this configuration back to JSON.
  Map<String, dynamic> toJson() => {
    if (android != null) 'android': android!.toJson(),
    if (ios != null) 'ios': ios!.toJson(),
    if (releaseNotes.isNotEmpty) 'release_notes': releaseNotes,
    if (maintenance != null) 'maintenance': maintenance!.toJson(),
  };
}
