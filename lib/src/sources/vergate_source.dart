import '../models/vergate_config.dart';

/// A provider of the remote [VergateConfig].
///
/// Implement this interface to load the configuration from any backend.
/// Implementations should throw when the config cannot be loaded; the
/// controller treats any thrown error as "unknown" and lets the user
/// continue (fail-open).
abstract interface class VergateSource {
  /// Loads the latest configuration.
  Future<VergateConfig> fetch();
}

/// Thrown by built-in sources when a configuration cannot be loaded.
class VergateSourceException implements Exception {
  /// Creates an exception with a human readable [message].
  const VergateSourceException(this.message, [this.cause]);

  /// What went wrong.
  final String message;

  /// The underlying error, if any.
  final Object? cause;

  @override
  String toString() => 'VergateSourceException: $message';
}
