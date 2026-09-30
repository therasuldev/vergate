import '../models/vergate_config.dart';
import 'vergate_source.dart';

/// A source backed by a plain async function.
///
/// This is the easiest way to plug in Firebase Remote Config, Supabase
/// or any other service without adding it as a dependency of Vergate.
///
/// ```dart
/// final source = CallbackSource(() async {
///   final json = await myApi.getVersionJson();
///   return VergateConfig.fromJsonString(json);
/// });
/// ```
class CallbackSource implements VergateSource {
  /// Creates a source that delegates to [callback].
  const CallbackSource(this._callback);

  final Future<VergateConfig> Function() _callback;

  @override
  Future<VergateConfig> fetch() => _callback();
}
