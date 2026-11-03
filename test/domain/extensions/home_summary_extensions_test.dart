import 'package:twake_chat/domain/model/app_twake_information.dart';
import 'package:twake_chat/domain/model/common_settings_information.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/domain/model/tom_server_information.dart';
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

  group('extract app.twake.chat information', () {
    test('homeserver summary include "app.twake.chat" information', () {
      final homeserver = HomeserverSummary(
        discoveryInformation: DiscoveryInformation(
          mHomeserver: HomeserverInformation(
            baseUrl: Uri.parse('https://matrix.twake.com'),
          ),
          mIdentityServer: IdentityServerInformation(
            baseUrl: Uri.parse('https://app.twake.com/'),
          ),
          additionalProperties: {
            'app.twake.chat': {
              'common_settings': {
                'enabled': true,
                'application_url': 'https://app.twake.com/',
              },
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

      const expected = AppTwakeInformation(
        commonSettingsInformation: CommonSettingsInformation(
          applicationUrl: 'https://app.twake.com/',
          enabled: true,
        ),
      );

      expect(homeserver.appTwakeInformation, equals(expected));
    });

    test('homeserver summary not include "app.twake.chat" information', () {
      final homeserver = HomeserverSummary(
        discoveryInformation: DiscoveryInformation(
          mHomeserver: HomeserverInformation(
            baseUrl: Uri.parse('https://matrix.twake.com'),
          ),
          mIdentityServer: IdentityServerInformation(
            baseUrl: Uri.parse('https://app.twake.com/'),
          ),
          additionalProperties: {
            'app.twake.chat-2': {
              'base_url': 'https://app.twake.com/',
              'server_name': 'twake.com',
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

      expect(homeserver.appTwakeInformation, isNull);
    });

    test('homeserver summary but additional properties is null', () {
      final homeserver = HomeserverSummary(
        discoveryInformation: DiscoveryInformation(
          mHomeserver: HomeserverInformation(
            baseUrl: Uri.parse('https://matrix.twake.com'),
          ),
          mIdentityServer: IdentityServerInformation(
            baseUrl: Uri.parse('https://app.twake.com/'),
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

      expect(homeserver.appTwakeInformation, isNull);
    });

    test('homeserver summary but discovery information is null', () {
      final homeserver = HomeserverSummary(
        discoveryInformation: null,
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

      expect(homeserver.appTwakeInformation, isNull);
    });

    test('homeserver summary with invalid "app.twake.chat" information', () {
      final homeserver = HomeserverSummary(
        discoveryInformation: DiscoveryInformation(
          mHomeserver: HomeserverInformation(
            baseUrl: Uri.parse('https://matrix.twake.com'),
          ),
          mIdentityServer: IdentityServerInformation(
            baseUrl: Uri.parse('https://app.twake.com/'),
          ),
          additionalProperties: {
            'app.twake.chat': {'invalid_key': 'invalid_value'},
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

      const expected = AppTwakeInformation(commonSettingsInformation: null);

      expect(homeserver.appTwakeInformation, equals(expected));
    });

    test('homeserver summary with "common_settings" being null', () {
      final homeserver = HomeserverSummary(
        discoveryInformation: DiscoveryInformation(
          mHomeserver: HomeserverInformation(
            baseUrl: Uri.parse('https://matrix.twake.com'),
          ),
          mIdentityServer: IdentityServerInformation(
            baseUrl: Uri.parse('https://app.twake.com/'),
          ),
          additionalProperties: {
            'app.twake.chat': {'common_settings': null},
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

      const expected = AppTwakeInformation(commonSettingsInformation: null);

      expect(homeserver.appTwakeInformation, equals(expected));
    });
  });

  group('public groups flags', () {
    HomeserverSummary summaryWith(Map<String, dynamic> additionalProperties) =>
        HomeserverSummary(
          discoveryInformation: DiscoveryInformation(
            mHomeserver: HomeserverInformation(
              baseUrl: Uri.parse('https://matrix.example.com'),
            ),
            additionalProperties: additionalProperties,
          ),
          versions: GetVersionsResponse(versions: ['r1.6.0']),
          loginFlows: [],
        );

    test('isPublicGroupsEnabled_whenWellKnownEnablesIt_returnsTrue', () {
      // Arrange
      final summary = summaryWith({
        'app.twake.chat': {
          'public_groups': {'enabled': true},
        },
      });

      // Act
      final isEnabled = summary.isPublicGroupsEnabled;

      // Assert
      expect(isEnabled, isTrue);
    });

    test('isPublicGroupsEnabled_whenKeyIsMissing_returnsFalse', () {
      // Arrange
      final summary = summaryWith({'app.twake.chat': <String, dynamic>{}});

      // Act
      final isEnabled = summary.isPublicGroupsEnabled;

      // Assert
      expect(isEnabled, isFalse);
    });

    test('isPublicGroupsEnabled_whenSummaryIsNull_returnsFalse', () {
      // Arrange
      const HomeserverSummary? summary = null;

      // Act
      final isEnabled = summary.isPublicGroupsEnabled;

      // Assert
      expect(isEnabled, isFalse);
    });

    test('isPublicGroupsEnabled_whenWellKnownIsMalformed_returnsFalse', () {
      // Arrange
      final summary = summaryWith({
        'app.twake.chat': {
          'public_groups': {'enabled': 'yes'},
        },
      });

      // Act
      final isEnabled = summary.isPublicGroupsEnabled;

      // Assert
      expect(isEnabled, isFalse);
    });

    test('isPublicGroupsServerAclEnabled_whenWellKnownSetsIt_returnsTrue', () {
      // Arrange
      final summary = summaryWith({
        'app.twake.chat': {
          'public_groups': {'enabled': true, 'server_acl': true},
        },
      });

      // Act
      final isServerAclEnabled = summary.isPublicGroupsServerAclEnabled;

      // Assert
      expect(isServerAclEnabled, isTrue);
    });

    test(
      'isPublicGroupsServerAclEnabled_whenWellKnownSetsFalse_returnsFalse',
      () {
        // Arrange
        final summary = summaryWith({
          'app.twake.chat': {
            'public_groups': {'enabled': true, 'server_acl': false},
          },
        });

        // Act
        final isServerAclEnabled = summary.isPublicGroupsServerAclEnabled;

        // Assert
        expect(isServerAclEnabled, isFalse);
      },
    );

    test('isPublicGroupsServerAclEnabled_whenKeyIsMissing_returnsFalse', () {
      // Arrange
      final summary = summaryWith({
        'app.twake.chat': {
          'public_groups': {'enabled': true},
        },
      });

      // Act
      final isServerAclEnabled = summary.isPublicGroupsServerAclEnabled;

      // Assert
      expect(isServerAclEnabled, isFalse);
    });
  });
}
