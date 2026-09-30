import '../models/vergate_config.dart';
import 'vergate_source.dart';

/// Tries several sources in order and returns the first successful result.
///
/// Useful to survive an outage of your primary backend:
/// ```dart
/// FallbackSource([
///   JsonUrlSource(Uri.parse('https://api.example.com/version')),
///   remoteConfigSource,
/// ]);
/// ```
class FallbackSource implements VergateSource {
  /// Creates a source that tries [sources] from first to last.
  FallbackSource(this.sources)
    : assert(sources.isNotEmpty, 'At least one source is required');

  /// Sources in priority order.
  final List<VergateSource> sources;

  @override
  Future<VergateConfig> fetch() async {
    Object? lastError;

    for (final source in sources) {
      try {
        return await source.fetch();
      } catch (e) {
        // Remember the error and move on to the next source.
        lastError = e;
      }
    }

    throw VergateSourceException('All sources failed', lastError);
  }
}
