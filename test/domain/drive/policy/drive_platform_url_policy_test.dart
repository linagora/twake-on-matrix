import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/drive/policy/drive_platform_url_policy.dart';

DriveIdToken _token(String? fqdn) => DriveIdToken(
  value: 't',
  expiresAt: DateTime.utc(2030),
  workplaceFqdn: fqdn,
);

void main() {
  const policy = DrivePlatformUrlPolicy();

  group('DrivePlatformUrlPolicy.resolve', () {
    test('is https and the host of the claim', () {
      final uri = policy.resolve(_token('alice.twake.example'));

      expect(uri, Uri.parse('https://alice.twake.example'));
    });

    test('lowercases the host', () {
      final uri = policy.resolve(_token('Alice.Twake.Example'));

      expect(uri.host, 'alice.twake.example');
    });

    test('is unknown when the token has no claim', () {
      expect(
        () => policy.resolve(_token(null)),
        throwsA(isA<DriveWorkplaceUnknown>()),
      );
      expect(
        () => policy.resolve(_token('')),
        throwsA(isA<DriveWorkplaceUnknown>()),
      );
    });

    for (final claim in [
      'evil.example/path',
      'user@evil.example',
      'alice.example:8443',
      'alice.example#frag',
      'alice example',
      '.alice.example',
      'alice.example.',
      'https://alice.example',
    ]) {
      test('is unknown when the claim is not a bare host: $claim', () {
        expect(
          () => policy.resolve(_token(claim)),
          throwsA(isA<DriveWorkplaceUnknown>()),
        );
      });
    }
  });
}
