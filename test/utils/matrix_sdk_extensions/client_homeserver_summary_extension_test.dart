import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/client_homeserver_summary_extension.dart';

import '../../fake_client.dart';
import 'client_well_known_extension_test.dart' show CachingDatabase;

const wellKnownPath = '/.well-known/matrix/client';
const versionsPath = '/client/versions';

HomeserverSummary summaryOf(String baseUrl, {required bool flagsOn}) =>
    HomeserverSummary(
      discoveryInformation: DiscoveryInformation.fromJson({
        'm.homeserver': {'base_url': baseUrl},
        'app.twake.chat': {
          'enable_invitations': flagsOn,
          'public_groups': {'enabled': flagsOn},
        },
      }),
      versions: GetVersionsResponse(versions: ['v1.11']),
      loginFlows: [LoginFlow(type: AuthenticationTypes.password)],
    );

void main() {
  group('ClientHomeserverSummaryExtension::fetchHomeserverSummary', () {
    late Client client;
    late CachingDatabase database;
    final otherAccountSummary = summaryOf(
      'https://other.example.com',
      flagsOn: true,
    );

    setUp(() async {
      database = CachingDatabase();
      client = await getClient(database: database);
    });

    tearDown(() async {
      await client.dispose(closeDatabase: false);
    });

    test('ignores the well-known of another homeserver when this one has '
        'neither a reachable nor a cached well-known', () async {
      FakeMatrixApi.currentApi!.api['GET']!.remove(wellKnownPath);

      final summary = await client.fetchHomeserverSummary(
        previous: otherAccountSummary,
      );

      expect(summary, isNotNull);
      expect(summary!.discoveryInformation, isNull);
      expect(summary.isInvitationEnabled, isFalse);
      expect(summary.isPublicGroupsEnabled, isFalse);
      expect(database.cache['well_known'], isNull);
    });

    test(
      'clears the summary when this homeserver is fully unreachable',
      () async {
        final api = FakeMatrixApi.currentApi!.api['GET']!;
        api.remove(wellKnownPath);
        api.remove(versionsPath);

        final summary = await client.fetchHomeserverSummary(
          previous: otherAccountSummary,
        );

        expect(summary, isNull);
      },
    );

    test('clears the summary when the client has no homeserver', () async {
      client.homeserver = null;

      final summary = await client.fetchHomeserverSummary(
        previous: otherAccountSummary,
      );

      expect(summary, isNull);
    });

    test('serves the own cached well-known over another homeserver', () async {
      FakeMatrixApi.currentApi!.api['GET']![wellKnownPath] = (_) => {
        'm.homeserver': {'base_url': 'https://fakeserver.notexisting'},
        'app.twake.chat': {'enable_invitations': false},
      };
      await client.fetchHomeserverSummary();
      database.cache['well_known'] = (
        content: database.cache['well_known']!.content,
        savedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      FakeMatrixApi.currentApi!.api['GET']!.remove(wellKnownPath);

      final summary = await client.fetchHomeserverSummary(
        previous: otherAccountSummary,
      );

      expect(
        summary!.discoveryInformation!.mHomeserver.baseUrl.host,
        'fakeserver.notexisting',
      );
      expect(summary.isInvitationEnabled, isFalse);
    });

    test('keeps the login summary of the same homeserver when its '
        'well-known cannot be fetched', () async {
      final api = FakeMatrixApi.currentApi!.api['GET']!;
      api.remove(wellKnownPath);
      api.remove(versionsPath);
      final loginSummary = summaryOf(
        'https://fakeserver.notexisting/',
        flagsOn: true,
      );

      final summary = await client.fetchHomeserverSummary(
        previous: loginSummary,
      );

      expect(summary!.isInvitationEnabled, isTrue);
      expect(summary.versions.versions, ['v1.11']);
      expect(database.cache['well_known'], isNotNull);
    });

    test('fetches the well-known when only the versions check fails', () async {
      final api = FakeMatrixApi.currentApi!.api['GET']!;
      api.remove(versionsPath);
      api[wellKnownPath] = (_) => {
        'm.homeserver': {'base_url': 'https://fakeserver.notexisting'},
        'app.twake.chat': {'enable_invitations': true},
      };

      final summary = await client.fetchHomeserverSummary();

      expect(summary!.isInvitationEnabled, isTrue);
    });

    test('keeps the homeserver and the session of an account whose '
        'homeserver check fails', () async {
      FakeMatrixApi.currentApi!.api['GET']!.remove(versionsPath);
      final stored = client.homeserver;
      var checkFailed = false;

      await client.fetchHomeserverSummary(
        onCheckFailed: () => checkFailed = true,
      );

      expect(checkFailed, isTrue);
      expect(client.homeserver, stored);
      expect(client.isLogged(), isTrue);
    });

    test(
      'does not report a failure when the homeserver check passes',
      () async {
        var checkFailed = false;

        await client.fetchHomeserverSummary(
          onCheckFailed: () => checkFailed = true,
        );

        expect(checkFailed, isFalse);
      },
    );
  });
}
