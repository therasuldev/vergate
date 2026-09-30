import '../core/json_utils.dart';

/// Maintenance mode settings.
///
/// Maintenance is active when [enabled] is `true` and the current time
/// falls inside the optional [from] / [until] window. A missing bound
/// means the window is open on that side.
class VergateMaintenance {
  /// Creates a maintenance configuration.
  const VergateMaintenance({
    this.enabled = false,
    this.from,
    this.until,
    this.message,
  });

  /// Creates a configuration from a decoded JSON map.
  ///
  /// Expected keys: `enabled`, `from`, `until`, `message`.
  factory VergateMaintenance.fromJson(Map<String, dynamic> json) {
    return VergateMaintenance(
      enabled: json['enabled'] == true,
      from: asUtcDate(json['from']),
      until: asUtcDate(json['until']),
      message: asNonEmptyString(json['message']),
    );
  }

  /// Master switch. When `false`, the time window is ignored.
  final bool enabled;

  /// Start of the maintenance window (UTC). `null` means "already started".
  final DateTime? from;

  /// End of the maintenance window (UTC). `null` means "until further notice".
  final DateTime? until;

  /// Optional custom message shown on the maintenance screen.
  final String? message;

  /// Whether maintenance is in effect at the given [now].
  bool isActiveAt(DateTime now) {
    if (!enabled) return false;

    final time = now.toUtc();
    if (from != null && time.isBefore(from!)) return false;
    if (until != null && time.isAfter(until!)) return false;
    return true;
  }

  /// Converts this configuration back to JSON.
  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    if (from != null) 'from': from!.toIso8601String(),
    if (until != null) 'until': until!.toIso8601String(),
    if (message != null) 'message': message,
  };
}
