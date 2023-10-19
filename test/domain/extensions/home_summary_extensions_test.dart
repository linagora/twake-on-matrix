import 'package:fluffychat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:fluffychat/domain/model/tom_server_information.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

void main() {
  group('extract tom server information', () {
    test('homeserver summary include "t.server" information', () {
      final homeserver = HomeserverSummary(
        discoveryInformation: DiscoveryInformation(
          mHomeserver: HomeserverInformation(
            baseUrl: Uri.parse('https://matrix.tom-dev.xyz'),
          ),
          mIdentityServer: IdentityServerInformation(
            baseUrl: Uri.parse('https://tom.tom-dev.xyz/'),
          ),
          additionalProperties: {
            't.server': {
              'base_url': 'https://tom.tom-dev.xyz/',
              'server_name': 'tom-dev.xyz',
            },
          },
        ),
        versions: GetVersionsResponse(
          versions: ['r1.6.0'],
          unstableFeatures: {},
        ),
        loginFlows: [
          LoginFlow(type: 'm.login.sso'),
          LoginFlow(type: 'm.login.token'),
          LoginFlow(type: 'm.login.application_service'),
        ],
      );

      final expected = ToMServerInformation(
        baseUrl: Uri.parse('https://tom.tom-dev.xyz/'),
        serverName: 'tom-dev.xyz',
      );

      expect(homeserver.tomServer, equals(expected));
    });

    test('homeserver summary not include "t.server" information', () {
      final homeserver = HomeserverSummary(
        discoveryInformation: DiscoveryInformation(
          mHomeserver: HomeserverInformation(
            baseUrl: Uri.parse('https://matrix.tom-dev.xyz'),
          ),
          mIdentityServer: IdentityServerInformation(
            baseUrl: Uri.parse('https://tom.tom-dev.xyz/'),
          ),
          additionalProperties: {
            't.server-2': {
              'base_url': 'https://tom.tom-dev.xyz/',
              'server_name': 'tom-dev.xyz',
            },
          },
        ),
        versions: GetVersionsResponse(
          versions: ['r1.6.0'],
          unstableFeatures: {},
        ),
        loginFlows: [
          LoginFlow(type: 'm.login.sso'),
          LoginFlow(type: 'm.login.token'),
          LoginFlow(type: 'm.login.application_service'),
        ],
      );

      expect(homeserver.tomServer, isNull);
    });

    test('homeserver summary but additional properties is null', () {
      final homeserver = HomeserverSummary(
        discoveryInformation: DiscoveryInformation(
          mHomeserver: HomeserverInformation(
            baseUrl: Uri.parse('https://matrix.tom-dev.xyz'),
          ),
          mIdentityServer: IdentityServerInformation(
            baseUrl: Uri.parse('https://tom.tom-dev.xyz/'),
          ),
        ),
        versions: GetVersionsResponse(
          versions: ['r1.6.0'],
          unstableFeatures: {},
        ),
        loginFlows: [
          LoginFlow(type: 'm.login.sso'),
          LoginFlow(type: 'm.login.token'),
          LoginFlow(type: 'm.login.application_service'),
        ],
      );

      expect(homeserver.tomServer, isNull);
    });
  });
}
