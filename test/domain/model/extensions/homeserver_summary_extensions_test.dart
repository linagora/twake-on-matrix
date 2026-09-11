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
  });
}
