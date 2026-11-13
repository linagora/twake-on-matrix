import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// A PKCE verifier and the challenge sent with the authorization request
/// (RFC 7636, method S256).
class PkcePair {
  const PkcePair({required this.verifier, required this.challenge});

  final String verifier;
  final String challenge;
}

class PkceGenerator {
  const PkceGenerator(this._random);

  /// A secure source in production; a seeded one in tests.
  final Random _random;

  static const _verifierBytes = 64;
  static const _tokenBytes = 16;

  PkcePair generate() {
    final verifier = _base64Url(_randomBytes(_verifierBytes));
    return PkcePair(verifier: verifier, challenge: challengeOf(verifier));
  }

  /// BASE64URL(SHA256(ASCII(verifier))) without padding.
  String challengeOf(String verifier) =>
      _base64Url(sha256.convert(ascii.encode(verifier)).bytes);

  /// An unguessable value for `state` and `nonce`.
  String randomToken() => _base64Url(_randomBytes(_tokenBytes));

  List<int> _randomBytes(int length) =>
      List<int>.generate(length, (_) => _random.nextInt(256));

  String _base64Url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}
