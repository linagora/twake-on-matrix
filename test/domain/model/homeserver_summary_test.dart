import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';

HomeserverSummary _summaryOf(String? baseUrl) => HomeserverSummary(
  discoveryInformation: baseUrl == null
      ? null
      : DiscoveryInformation(
          mHomeserver: HomeserverInformation(baseUrl: Uri.parse(baseUrl)),
        ),
  versions: GetVersionsResponse(versions: ['r1.6.0']),
  loginFlows: [],
);

void main() {
  group('HomeserverSummary.isOf', () {
    test('is true for the homeserver it was discovered for', () {
      expect(
        _summaryOf(
          'https://matrix.a.example',
        ).isOf(Uri.parse('https://matrix.a.example')),
        isTrue,
      );
    });

    test('ignores a trailing slash and the default port', () {
      expect(
        _summaryOf(
          'https://matrix.a.example/',
        ).isOf(Uri.parse('https://matrix.a.example:443')),
        isTrue,
      );
    });

    test('is false for the homeserver of another account', () {
      expect(
        _summaryOf(
          'https://matrix.a.example',
        ).isOf(Uri.parse('https://matrix.b.example')),
        isFalse,
      );
    });

    test('is false for another port of the same host', () {
      expect(
        _summaryOf(
          'https://matrix.a.example',
        ).isOf(Uri.parse('https://matrix.a.example:8448')),
        isFalse,
      );
    });

    test('is false without discovery information or without a homeserver', () {
      expect(
        _summaryOf(null).isOf(Uri.parse('https://matrix.a.example')),
        isFalse,
      );
      expect(_summaryOf('https://matrix.a.example').isOf(null), isFalse);
    });
  });
}
