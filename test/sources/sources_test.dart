import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vergate/vergate.dart';

http.Response _json(String body, [int status = 200]) => http.Response(
      body,
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('JsonUrlSource', () {
    final url = Uri.parse('https://api.example.com/version');

    test('parses a valid response and sends headers', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return _json('{"android": {"min_version": "1.2.0"}}');
      });

      final source = JsonUrlSource(
        url,
        headers: {'Authorization': 'Bearer token'},
        client: client,
      );
      final config = await source.fetch();

      expect(config.android!.minVersion, const AppVersion(1, 2, 0));
      expect(captured.headers['Authorization'], 'Bearer token');
    });

    test('throws VergateSourceException on non-200', () {
      final client = MockClient((_) async => _json('oops', 500));
      expect(
        JsonUrlSource(url, client: client).fetch(),
        throwsA(isA<VergateSourceException>()),
      );
    });

    test('throws VergateSourceException on invalid JSON', () {
      final client = MockClient((_) async => _json('not json'));
      expect(
        JsonUrlSource(url, client: client).fetch(),
        throwsA(isA<VergateSourceException>()),
      );
    });

    test('throws VergateSourceException on timeout', () {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return _json('{}');
      });
      final source = JsonUrlSource(
        url,
        client: client,
        timeout: const Duration(milliseconds: 20),
      );
      expect(source.fetch(), throwsA(isA<VergateSourceException>()));
    });
  });

  group('ItunesLookupSource', () {
    const body = '''
    {"resultCount": 1, "results": [{
      "version": "2.1.0",
      "trackViewUrl": "https://apps.apple.com/app/id123",
      "releaseNotes": "- Faster search\\n• Bug fixes\\n\\n"
    }]}''';

    test('maps the response to an iOS config', () async {
      late Uri requested;
      final client = MockClient((request) async {
        requested = request.url;
        return _json(body);
      });

      final config = await ItunesLookupSource(
        bundleId: 'com.example.app',
        country: 'az',
        client: client,
      ).fetch();

      expect(requested.queryParameters['bundleId'], 'com.example.app');
      expect(requested.queryParameters['country'], 'az');
      expect(config.ios!.latestVersion, const AppVersion(2, 1, 0));
      expect(config.ios!.storeUrl, 'https://apps.apple.com/app/id123');
      expect(config.ios!.minVersion, isNull);
      expect(config.releaseNotes, ['Faster search', 'Bug fixes']);
    });

    test('throws when the app is not listed', () {
      final client = MockClient(
        (_) async => _json('{"resultCount": 0, "results": []}'),
      );
      expect(
        ItunesLookupSource(bundleId: 'com.none', client: client).fetch(),
        throwsA(isA<VergateSourceException>()),
      );
    });
  });

  group('CallbackSource & FallbackSource', () {
    test('CallbackSource returns the callback result', () async {
      final source = CallbackSource(
        () async => VergateConfig.fromJson({'release_notes': ['Hi']}),
      );
      expect((await source.fetch()).releaseNotes, ['Hi']);
    });

    test('FallbackSource skips failing sources', () async {
      final source = FallbackSource([
        CallbackSource(() async => throw Exception('backend down')),
        CallbackSource(() async => const VergateConfig(releaseNotes: ['ok'])),
      ]);
      expect((await source.fetch()).releaseNotes, ['ok']);
    });

    test('FallbackSource throws when every source fails', () {
      final source = FallbackSource([
        CallbackSource(() async => throw Exception('a')),
        CallbackSource(() async => throw Exception('b')),
      ]);
      expect(source.fetch(), throwsA(isA<VergateSourceException>()));
    });
  });
}