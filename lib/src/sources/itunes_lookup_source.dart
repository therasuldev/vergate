import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/app_version.dart';
import '../core/json_utils.dart';
import '../models/platform_config.dart';
import '../models/vergate_config.dart';
import 'vergate_source.dart';

/// Reads the newest published iOS version from the App Store.
///
/// It fills only `ios.latest_version`, `ios.store_url` and the release
/// notes, so it produces **soft updates** only. It cannot know your
/// minimum supported version. Combine it with another source for force
/// updates, or use it alone for a simple "new version available" banner.
///
/// Notes:
/// * Pass [country] (for example `az`) when the app is not available in
///   the US store, otherwise the lookup may return nothing.
/// * The App Store can lag behind a release by several hours.
class ItunesLookupSource implements VergateSource {
  /// Creates a source for the app with the given iOS [bundleId].
  ItunesLookupSource({
    required this.bundleId,
    this.country,
    this.timeout = const Duration(seconds: 10),
    this._client,
  });

  /// The iOS bundle identifier, e.g. `com.example.app`.
  final String bundleId;

  /// Two-letter store country code, e.g. `az`, `us`, `tr`.
  final String? country;

  /// Maximum time to wait for the response.
  final Duration timeout;

  final http.Client? _client;

  @override
  Future<VergateConfig> fetch() async {
    final uri = Uri.https('itunes.apple.com', '/lookup', {
      'bundleId': bundleId,
      'country': ?country,
    });

    final client = _client ?? http.Client();
    try {
      final response = await client.get(uri).timeout(timeout);
      if (response.statusCode != 200) {
        throw VergateSourceException(
          'Unexpected status code ${response.statusCode} from iTunes Lookup',
        );
      }

      final body = asJsonMap(jsonDecode(utf8.decode(response.bodyBytes)));
      final results = body?['results'];
      if (results is! List || results.isEmpty) {
        throw VergateSourceException(
          'No App Store listing found for "$bundleId"'
          '${country == null ? '' : ' in country "$country"'}',
        );
      }

      final app = asJsonMap(results.first);
      final latest = AppVersion.tryParse(asNonEmptyString(app?['version']));
      if (latest == null) {
        throw const VergateSourceException(
          'iTunes Lookup response has no valid version',
        );
      }

      return VergateConfig(
        ios: VergatePlatformConfig(
          latestVersion: latest,
          storeUrl: asNonEmptyString(app?['trackViewUrl']),
        ),
        releaseNotes: _splitNotes(asNonEmptyString(app?['releaseNotes'])),
      );
    } on VergateSourceException {
      rethrow;
    } on TimeoutException catch (e) {
      throw VergateSourceException('iTunes Lookup timed out', e);
    } catch (e) {
      throw VergateSourceException('iTunes Lookup failed', e);
    } finally {
      if (_client == null) client.close();
    }
  }

  /// Splits App Store release notes into clean lines without bullet marks.
  static List<String> _splitNotes(String? notes) {
    if (notes == null) return const [];
    return notes
        .split('\n')
        .map((line) => line.replaceFirst(RegExp(r'^\s*[-•*]\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }
}
