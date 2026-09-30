/// Internal helpers for reading loosely typed JSON safely.
///
/// Remote configs are edited by humans, so parsing must be lenient:
/// wrong types are ignored instead of crashing the host app.
library;

/// Returns [value] as a `Map<String, dynamic>`, or `null` if it is not a map.
Map<String, dynamic>? asJsonMap(Object? value) {
  if (value is! Map) return null;
  return value.map((key, val) => MapEntry(key.toString(), val));
}

/// Returns [value] as a list of strings, ignoring any non-string entries.
List<String> asStringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

/// Returns [value] as a trimmed non-empty string, or `null`.
String? asNonEmptyString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Parses an ISO 8601 date string into UTC, or returns `null`.
///
/// Always include a time zone (for example `2026-10-01T22:00:00Z`).
/// Values without a zone are treated as device local time.
DateTime? asUtcDate(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toUtc();
}
