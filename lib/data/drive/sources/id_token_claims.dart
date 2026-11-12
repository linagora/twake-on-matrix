import 'dart:convert';

/// The claims of an id token the sign-in checks and reads. The signature is
/// not checked: the token comes straight from the token endpoint over TLS
/// (OIDC Core 3.1.3.7, item 6).
class IdTokenClaims {
  const IdTokenClaims({
    required this.issuer,
    required this.audience,
    required this.expiresAt,
    this.authorizedParty,
    this.nonce,
    this.workplaceFqdn,
    this.subject,
    this.email,
  });

  /// Throws a [FormatException] when [jwt] is not a JWT with the claims every
  /// id token has.
  factory IdTokenClaims.parse(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) throw const FormatException('not a JWT');
    final decoded = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('claims are not an object');
    }
    return IdTokenClaims._fromClaims(decoded);
  }

  factory IdTokenClaims._fromClaims(Map<String, dynamic> claims) {
    final iss = claims['iss'];
    if (iss is! String) throw const FormatException('invalid id token claims');
    return IdTokenClaims(
      issuer: iss,
      audience: _audienceOf(claims['aud']),
      authorizedParty: _optionalString(claims['azp']),
      expiresAt: _expiryOf(claims['exp']),
      nonce: _asString(claims['nonce']),
      workplaceFqdn: _asString(claims['workplaceFqdn']),
      subject: _asString(claims['sub']),
      email: _asString(claims['email']),
    );
  }

  /// The last second a `DateTime` can hold, in milliseconds / 1000.
  static const _maxExpSeconds = 8640000000000;

  final String issuer;

  /// `aud` is a string or a list of strings; the SSO sends a list.
  final List<String> audience;
  final String? authorizedParty;
  final DateTime expiresAt;
  final String? nonce;
  final String? workplaceFqdn;
  final String? subject;
  final String? email;

  /// The `exp` claim as a date; a value a `DateTime` cannot hold is malformed.
  static DateTime _expiryOf(Object? exp) {
    if (exp is! int) throw const FormatException('invalid id token claims');
    if (!_isRepresentable(exp)) {
      throw const FormatException('invalid id token claims');
    }
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
  }

  static bool _isRepresentable(int seconds) =>
      seconds >= 0 && seconds <= _maxExpSeconds;

  static String? _asString(Object? value) => value is String ? value : null;

  static List<String> _audienceOf(Object? aud) =>
      aud is List ? aud.whereType<String>().toList() : [?_asString(aud)];

  /// A claim that may be missing but, when present, is a string.
  static String? _optionalString(Object? value) {
    if (value != null && value is! String) {
      throw const FormatException('invalid id token claims');
    }
    return value as String?;
  }
}
