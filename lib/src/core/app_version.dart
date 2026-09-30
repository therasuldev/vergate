/// An immutable, comparable representation of an application version.
///
/// Supports the common formats used by Flutter apps:
/// `1`, `1.2`, `1.2.3`, `v1.2.3` and `1.2.3+45` (with build number).
/// Pre-release suffixes such as `-beta.1` are ignored when comparing.
class AppVersion implements Comparable<AppVersion> {
  /// Creates a version from its numeric parts.
  const AppVersion(
    this.major, [
    this.minor = 0,
    this.patch = 0,
    this.build = 0,
  ]);

  /// Parses [input] into an [AppVersion].
  ///
  /// Throws a [FormatException] if [input] is not a valid version string.
  factory AppVersion.parse(String input) {
    final match = _pattern.firstMatch(input.trim());
    if (match == null) {
      throw FormatException('Invalid app version format', input);
    }
    return AppVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2) ?? '0'),
      int.parse(match.group(3) ?? '0'),
      int.parse(match.group(4) ?? '0'),
    );
  }

  /// Parses [input] and returns `null` instead of throwing on failure.
  static AppVersion? tryParse(String? input) {
    if (input == null) return null;
    try {
      return AppVersion.parse(input);
    } on FormatException {
      return null;
    }
  }

  /// Matches: optional "v" prefix, up to three numeric parts,
  /// an ignored pre-release tag and an optional "+build" number.
  static final RegExp _pattern = RegExp(
    r'^v?(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:-[0-9A-Za-z.\-]+)?(?:\+(\d+))?$',
  );

  /// Major version number (breaking changes).
  final int major;

  /// Minor version number (new features).
  final int minor;

  /// Patch version number (bug fixes).
  final int patch;

  /// Build number (the part after `+`). Defaults to `0`.
  final int build;

  /// Whether this version is strictly lower than [other].
  bool operator <(AppVersion other) => compareTo(other) < 0;

  /// Whether this version is lower than or equal to [other].
  bool operator <=(AppVersion other) => compareTo(other) <= 0;

  /// Whether this version is strictly higher than [other].
  bool operator >(AppVersion other) => compareTo(other) > 0;

  /// Whether this version is higher than or equal to [other].
  bool operator >=(AppVersion other) => compareTo(other) >= 0;

  @override
  int compareTo(AppVersion other) {
    final byMajor = major.compareTo(other.major);
    if (byMajor != 0) return byMajor;

    final byMinor = minor.compareTo(other.minor);
    if (byMinor != 0) return byMinor;

    final byPatch = patch.compareTo(other.patch);
    if (byPatch != 0) return byPatch;

    return build.compareTo(other.build);
  }

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch, build);

  @override
  String toString() =>
      build == 0 ? '$major.$minor.$patch' : '$major.$minor.$patch+$build';
}
