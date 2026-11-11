import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:matrix/matrix.dart';

void main() {
  HomeserverSummary summaryWith(Map<String, dynamic> additionalProperties) =>
      HomeserverSummary(
        discoveryInformation: DiscoveryInformation(
          additionalProperties: additionalProperties,
          mHomeserver: HomeserverInformation(
            baseUrl: Uri.parse('https://matrix.domain.xyz'),
          ),
        ),
        versions: GetVersionsResponse(versions: []),
        loginFlows: [],
      );

  group('NullableHomeserverSummaryExtensions', () {
    test('isInvitationEnabled returns true when invitations are enabled', () {
      final summary = summaryWith({
        'app.twake.chat': {'enable_invitations': true},
      });

      expect(summary.isInvitationEnabled, isTrue);
    });

    test('isInvitationEnabled returns false when invitations are disabled', () {
      final summary = summaryWith({
        'app.twake.chat': {'enable_invitations': false},
      });

      expect(summary.isInvitationEnabled, isFalse);
    });

    test('isInvitationEnabled returns false when the summary is null', () {
      const HomeserverSummary? summary = null;

      expect(summary.isInvitationEnabled, isFalse);
    });

    test('isInvitationEnabled returns false when the key is missing', () {
      final summary = summaryWith({
        'app.twake.chat': {'support_contact': '@support:twake.app'},
      });

      expect(summary.isInvitationEnabled, isFalse);
    });

    test('isInvitationEnabled returns false when app.twake.chat is absent', () {
      final summary = summaryWith({
        't.server': {'base_url': 'https://tom.domain.xyz/'},
      });

      expect(summary.isInvitationEnabled, isFalse);
    });

    test('isInvitationEnabled returns false when the flag is not a bool', () {
      final summary = summaryWith({
        'app.twake.chat': {'enable_invitations': 'true'},
      });

      expect(summary.isInvitationEnabled, isFalse);
    });
    group('callTokenServiceUrl', () {
      Map<String, dynamic> foci(List<Map<String, Object?>> foci) => {
        'org.matrix.msc4143.rtc_foci': foci,
      };

      test('prefers the service url of the LiveKit focus', () {
        final summary = summaryWith(
          foci([
            {
              'type': 'livekit',
              'livekit_service_url': 'https://rtc.test/',
              'livekit_base_url': 'https://meet.test',
            },
          ]),
        );

        expect(summary.callTokenServiceUrl, 'https://rtc.test');
        expect(summary.videoCallBaseUrl, 'https://meet.test');
      });

      test('has no token service with a base url alone', () {
        final summary = summaryWith(
          foci([
            {'type': 'livekit', 'livekit_base_url': 'https://meet.test'},
          ]),
        );

        expect(summary.callTokenServiceUrl, isNull);
        expect(summary.videoCallBaseUrl, 'https://meet.test');
      });

      test('refuses a service url that is not https', () {
        final summary = summaryWith(
          foci([
            {'type': 'livekit', 'livekit_service_url': 'http://rtc.test'},
            {'type': 'livekit', 'livekit_service_url': 'https://rtc2.test'},
          ]),
        );

        expect(summary.callTokenServiceUrl, 'https://rtc2.test');
      });

      test('accepts http on this machine, for local servers', () {
        final summary = summaryWith(
          foci([
            {'type': 'livekit', 'livekit_service_url': 'http://127.0.0.1:3003'},
          ]),
        );

        expect(summary.callTokenServiceUrl, 'http://127.0.0.1:3003');
      });

      test('ignores a focus of another type', () {
        final summary = summaryWith(
          foci([
            {'type': 'other', 'livekit_service_url': 'https://rtc.test'},
          ]),
        );

        expect(summary.callTokenServiceUrl, isNull);
      });
    });

    group('webAppOrigin', () {
      String? originOf(Object? webUrl) => summaryWith({
        'app.twake.chat': {'web_url': webUrl},
      }).webAppOrigin;

      test('is the origin of the configured web URL', () {
        expect(
          originOf('https://chat.example.org'),
          'https://chat.example.org',
        );
      });

      test('drops a trailing slash, path and query', () {
        expect(
          originOf('https://chat.example.org:8443/app/?x=1'),
          'https://chat.example.org:8443',
        );
      });

      test('is null when the URL is missing, not https or not a URL', () {
        expect(originOf(null), isNull);
        expect(originOf(''), isNull);
        expect(originOf('http://chat.example.org'), isNull);
        expect(originOf('chat.example.org'), isNull);
      });

      test('is null without app.twake.chat or without a summary', () {
        expect(summaryWith({}).webAppOrigin, isNull);
        expect((null as HomeserverSummary?).webAppOrigin, isNull);
      });
    });
  });
}
