import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';

HomeserverSummary _summary(Map<String, Object?>? wellKnown) =>
    HomeserverSummary(
      discoveryInformation: wellKnown == null
          ? null
          : DiscoveryInformation.fromJson({
              'm.homeserver': {'base_url': 'https://matrix.example/'},
              ...wellKnown,
            }),
      versions: GetVersionsResponse(versions: const ['v1.11']),
      loginFlows: const [],
    );

void main() {
  group('HomeserverSummary.ssoIssuer', () {
    test('is the issuer of m.authentication', () {
      final summary = _summary({
        'm.authentication': {'issuer': 'https://sso.example/'},
      });

      expect(summary.ssoIssuer, 'https://sso.example/');
    });

    final absent = <String, Map<String, Object?>?>{
      'there is no well-known': null,
      'm.authentication is missing': <String, Object?>{},
      'm.authentication is not an object': {'m.authentication': 'https://x'},
      'the issuer is missing': {'m.authentication': <String, Object?>{}},
      'the issuer is empty': {
        'm.authentication': {'issuer': ''},
      },
      'the issuer is not a string': {
        'm.authentication': {'issuer': 42},
      },
    };
    absent.forEach((reason, wellKnown) {
      test('is null when $reason', () {
        expect(_summary(wellKnown).ssoIssuer, isNull);
      });
    });
  });
}
