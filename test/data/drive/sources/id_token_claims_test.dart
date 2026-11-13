import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/drive/sources/id_token_claims.dart';

String _segment(Object json) =>
    base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

String _jwt(Map<String, Object?> claims) =>
    '${_segment({'alg': 'RS512'})}.${_segment(claims)}.signature';

void main() {
  group('IdTokenClaims.parse', () {
    test('reads the claims the SSO sends, with aud as a list', () {
      final claims = IdTokenClaims.parse(
        _jwt({
          'iss': 'https://sso.example',
          'aud': ['matrix1', 'matrix1'],
          'exp': 1793722108,
          'workplaceFqdn': 'alice.twake.example',
          'email': 'alice@example.com',
          'sub': 'alice',
          'azp': 'matrix1',
        }),
      );

      expect(claims.issuer, 'https://sso.example');
      expect(claims.audience, ['matrix1', 'matrix1']);
      expect(
        claims.expiresAt,
        DateTime.fromMillisecondsSinceEpoch(1793722108 * 1000, isUtc: true),
      );
      expect(claims.workplaceFqdn, 'alice.twake.example');
      expect(claims.subject, 'alice');
      expect(claims.email, 'alice@example.com');
      expect(claims.nonce, isNull);
      expect(claims.authorizedParty, 'matrix1');
    });

    test('reads aud given as a single string', () {
      final claims = IdTokenClaims.parse(
        _jwt({'iss': 'https://sso.example', 'aud': 'matrix1', 'exp': 10}),
      );

      expect(claims.audience, ['matrix1']);
    });

    test('reads a payload whose base64url has no padding', () {
      // Claims of a length that needs padding when decoded.
      final claims = IdTokenClaims.parse(
        _jwt({'iss': 'a', 'aud': 'b', 'exp': 1, 'nonce': 'n'}),
      );

      expect(claims.nonce, 'n');
    });

    test('rejects a token without three parts', () {
      expect(() => IdTokenClaims.parse('a.b'), throwsFormatException);
    });

    test('rejects a payload that is malformed JSON', () {
      final broken = base64Url
          .encode(utf8.encode('{"iss":'))
          .replaceAll('=', '');

      expect(() => IdTokenClaims.parse('x.$broken.y'), throwsFormatException);
    });

    test('rejects a payload that is not base64', () {
      expect(() => IdTokenClaims.parse('x.%%%.y'), throwsFormatException);
    });

    test('rejects a payload that is not JSON', () {
      expect(
        () => IdTokenClaims.parse('x.${_segment('text')}.y'),
        throwsFormatException,
      );
    });

    test('rejects an exp that a date cannot hold', () {
      for (final exp in [-1, 8640000000001, 1 << 62]) {
        expect(
          () => IdTokenClaims.parse(
            _jwt({'iss': 'a', 'aud': 'matrix1', 'exp': exp}),
          ),
          throwsFormatException,
        );
      }
    });

    test('rejects an azp that is not a string', () {
      expect(
        () => IdTokenClaims.parse(
          _jwt({'iss': 'a', 'aud': 'matrix1', 'exp': 1, 'azp': 42}),
        ),
        throwsFormatException,
      );
    });

    test('rejects claims without iss or exp', () {
      expect(
        () => IdTokenClaims.parse(_jwt({'aud': 'matrix1', 'exp': 1})),
        throwsFormatException,
      );
      expect(
        () => IdTokenClaims.parse(_jwt({'iss': 'a', 'aud': 'matrix1'})),
        throwsFormatException,
      );
    });

    test('rejects a non-string authorized party', () {
      expect(
        () => IdTokenClaims.parse(
          _jwt({'iss': 'a', 'aud': 'b', 'exp': 1, 'azp': 3}),
        ),
        throwsFormatException,
      );
    });
  });
}
