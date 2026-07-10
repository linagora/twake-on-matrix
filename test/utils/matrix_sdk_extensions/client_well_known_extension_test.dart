import 'package:fluffychat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:fluffychat/domain/model/homeserver_summary.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/client_well_known_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';

import '../../fake_client.dart';

/// Records every URI the client requests while delegating to [FakeMatrixApi],
/// so tests can assert which host a request was sent to.
class RecordingHttpClient extends http.BaseClient {
  final List<Uri> requestedUris = [];
  final http.Client _inner = FakeMatrixApi();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requestedUris.add(request.url);
    return _inner.send(request);
  }
}

/// Persists custom cache objects in memory so the SDK cache fallback path can
/// be exercised.
class CachingDatabase extends MockDatabase {
  final Map<String, ({Map<String, Object?> content, DateTime savedAt})> cache =
      {};

  @override
  Future<({Map<String, Object?> content, DateTime savedAt})?>
  getCustomCacheObject(String key) async => cache[key];

  @override
  Future<void> cacheCustomObject(
    String key,
    Map<String, Object?> content, {
    DateTime? savedAt,
  }) async {
    cache[key] = (content: content, savedAt: savedAt ?? DateTime.now());
  }
}

const wellKnownPath = '/.well-known/matrix/client';

Map<String, Object?> wellKnownWithLiveKit(dynamic req) => {
  'm.homeserver': {'base_url': 'https://fakeserver.notexisting'},
  'org.matrix.msc4143.rtc_foci': [
    {'type': 'livekit', 'livekit_base_url': 'https://livekit.example.com/'},
  ],
};

HomeserverSummary summaryOf(DiscoveryInformation? discovery) =>
    HomeserverSummary(
      discoveryInformation: discovery,
      versions: GetVersionsResponse(versions: ['v1.11']),
      loginFlows: [],
    );

void main() {
  group('ClientWellKnownExtension::getWellKnownOrFallback', () {
    late Client client;

    tearDown(() async {
      await client.dispose(closeDatabase: false);
    });

    test('exposes the livekit url from a freshly fetched well-known', () async {
      client = await getClient();
      final fakeApi = FakeMatrixApi.currentApi!;
      fakeApi.api['GET']![wellKnownPath] = wellKnownWithLiveKit;

      final discovery = await client.getWellKnownOrFallback();

      // The fake user's domain (https://fakeserver) is not a known server of
      // FakeMatrixApi: this only passes because the fetch targets the
      // homeserver host, not userID.domain (the 404 source of #3050).
      expect(
        summaryOf(discovery).videoCallBaseUrl,
        'https://livekit.example.com',
      );
    });

    test('targets the homeserver host, never the MXID domain', () async {
      final recorder = RecordingHttpClient();
      client = await getClient(httpClient: recorder);
      final fakeApi = FakeMatrixApi.currentApi!;
      fakeApi.api['GET']![wellKnownPath] = wellKnownWithLiveKit;

      final discovery = await client.getWellKnownOrFallback();
      expect(discovery, isNotNull);

      final uris = List.of(recorder.requestedUris);
      final wellKnownUris = uris.where((uri) => uri.path == wellKnownPath);
      expect(wellKnownUris, isNotEmpty);
      expect(
        wellKnownUris.every((uri) => uri.host == client.homeserver!.host),
        isTrue,
        reason: 'well-known must be fetched from the homeserver host',
      );
      // The logged-in user is @admin:fakeServer: no request may ever target
      // their MXID domain (the 404 source of #3050).
      expect(
        uris.any((uri) => uri.host == 'fakeserver'),
        isFalse,
        reason: 'no request may target the MXID domain',
      );
    });

    test(
      'returns the fallback when the well-known cannot be fetched',
      () async {
        client = await getClient();
        final fakeApi = FakeMatrixApi.currentApi!;
        fakeApi.api['GET']!.remove(wellKnownPath);
        final previous = DiscoveryInformation(
          mHomeserver: HomeserverInformation(
            baseUrl: Uri.parse('https://fakeserver.notexisting'),
          ),
        );

        final discovery = await client.getWellKnownOrFallback(
          fallback: previous,
        );

        expect(discovery, same(previous));
      },
    );

    test('serves the persisted well-known without a network attempt when the '
        'homeserver is unset', () async {
      final database = CachingDatabase();
      final recorder = RecordingHttpClient();
      client = await getClient(database: database, httpClient: recorder);
      FakeMatrixApi.currentApi!.api['GET']![wellKnownPath] =
          wellKnownWithLiveKit;

      // Seed the persisted copy with a successful fetch, then age it past
      // the cache lifetime so freshness alone cannot serve the next call.
      await client.getWellKnownOrFallback();
      database.cache['well_known'] = (
        content: database.cache['well_known']!.content,
        savedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      // What checkHomeserver() leaves behind when the server is fully
      // unreachable at startup.
      final homeserver = client.homeserver;
      client.homeserver = null;

      final requestsBefore = recorder.requestedUris
          .where((uri) => uri.path == wellKnownPath)
          .length;
      final discovery = await client.getWellKnownOrFallback();
      final requestsAfter = recorder.requestedUris
          .where((uri) => uri.path == wellKnownPath)
          .length;
      client.homeserver = homeserver;

      expect(
        summaryOf(discovery).videoCallBaseUrl,
        'https://livekit.example.com',
      );
      expect(
        requestsAfter,
        requestsBefore,
        reason: 'no network attempt may be made without a homeserver',
      );
    });

    test('serves the persisted well-known when a later fetch fails', () async {
      final database = CachingDatabase();
      client = await getClient(database: database);
      final fakeApi = FakeMatrixApi.currentApi!;
      fakeApi.api['GET']![wellKnownPath] = wellKnownWithLiveKit;

      await client.getWellKnownOrFallback();
      expect(database.cache['well_known'], isNotNull);

      // Simulate a restart after the cache lifetime with the server
      // unreachable: the SDK must serve the persisted copy.
      database.cache['well_known'] = (
        content: database.cache['well_known']!.content,
        savedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      fakeApi.api['GET']!.remove(wellKnownPath);

      final discovery = await client.getWellKnownOrFallback();

      expect(
        summaryOf(discovery).videoCallBaseUrl,
        'https://livekit.example.com',
      );
    });
  });
}
