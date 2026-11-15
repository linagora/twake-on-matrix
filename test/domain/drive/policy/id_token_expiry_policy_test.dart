import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/policy/id_token_expiry_policy.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 12);
  const policy = IdTokenExpiryPolicy(skew: Duration(seconds: 60));

  DriveIdToken tokenExpiringIn(Duration left) =>
      DriveIdToken(value: 't', expiresAt: now.add(left));

  group('IdTokenExpiryPolicy.isUsable', () {
    test('a token with 61 s left is usable', () {
      expect(
        policy.isUsable(tokenExpiringIn(const Duration(seconds: 61)), now),
        isTrue,
      );
    });

    test('a token with exactly the skew left is not usable', () {
      expect(
        policy.isUsable(tokenExpiringIn(const Duration(seconds: 60)), now),
        isFalse,
      );
    });

    test('a token with 59 s left is not usable', () {
      expect(
        policy.isUsable(tokenExpiringIn(const Duration(seconds: 59)), now),
        isFalse,
      );
    });

    test('an expired token is not usable', () {
      expect(
        policy.isUsable(tokenExpiringIn(const Duration(hours: -1)), now),
        isFalse,
      );
    });
  });
}
