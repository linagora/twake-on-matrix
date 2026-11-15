import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/policy/drive_account_policy.dart';

DriveIdToken _token({String? subject, String? email}) => DriveIdToken(
  value: 'id',
  expiresAt: DateTime.utc(2100),
  subject: subject,
  email: email,
);

void main() {
  const policy = DriveAccountPolicy();

  bool owns(DriveIdToken token, {int others = 1}) =>
      policy.owns(token, localpart: 'alice', otherAccountsOnServer: others);

  group('DriveAccountPolicy.owns', () {
    test('a token whose subject is the localpart is the account\'s', () {
      expect(owns(_token(subject: 'alice')), isTrue);
    });

    test('a name in another case is still the account\'s', () {
      expect(owns(_token(email: 'Alice@example.org')), isTrue);
      expect(owns(_token(subject: 'ALICE')), isTrue);
    });

    test(
      'a token whose e-mail starts with the localpart is the account\'s',
      () {
        expect(
          owns(_token(subject: 'u-42', email: 'alice@example.org')),
          isTrue,
        );
      },
    );

    test('a token of someone else is not, while another account could be '
        'that person', () {
      expect(owns(_token(subject: 'bob', email: 'bob@example.org')), isFalse);
    });

    test('a token of someone else still serves the only account of its '
        'homeserver', () {
      expect(owns(_token(subject: 'u-42'), others: 0), isTrue);
    });

    test('a token that names nobody serves only the only account', () {
      expect(owns(_token()), isFalse);
      expect(owns(_token(), others: 0), isTrue);
    });
  });
}
