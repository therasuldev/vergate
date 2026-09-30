import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/vergate_config.dart';
import 'vergate_source.dart';

/// Loads the configuration from a JSON document served over HTTP(S).
///
/// The response body must match the format documented on [VergateConfig].
/// Works with your own backend, GitHub raw files, S3, Cloudflare R2, etc.
class JsonUrlSource implements VergateSource {
  /// Creates a source that reads from [url].
  ///
  /// Use [headers] for authentication, [timeout] to limit waiting time,
  /// and [_client] to inject a custom (or mock) HTTP client.
  JsonUrlSource(
    this.url, {
    this.headers = const {},
    this.timeout = const Duration(seconds: 10),
    this._client,
  });

  /// The address of the JSON document.
  final Uri url;

  /// Extra HTTP headers sent with the request.
  final Map<String, String> headers;

  /// Maximum time to wait for the response.
  final Duration timeout;

  final http.Client? _client;

  @override
  Future<VergateConfig> fetch() async {
    // Only close clients that we created ourselves.
    final client = _client ?? http.Client();
    try {
      final response = await client.get(url, headers: headers).timeout(timeout);

      if (response.statusCode != 200) {
        throw VergateSourceException(
          'Unexpected status code ${response.statusCode} from $url',
        );
      }
      return VergateConfig.fromJsonString(utf8.decode(response.bodyBytes));
    } on VergateSourceException {
      rethrow;
    } on TimeoutException catch (e) {
      throw VergateSourceException('Request to $url timed out', e);
    } on FormatException catch (e) {
      throw VergateSourceException('Invalid JSON received from $url', e);
    } catch (e) {
      throw VergateSourceException('Failed to load config from $url', e);
    } finally {
      if (_client == null) client.close();
    }
  }
}
