import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';

void main() {
  const secret = 'eyJhbGciOiJSUzUxMiJ9.secret-payload.secret-signature';
  final token = DriveIdToken(
    value: secret,
    expiresAt: DateTime.utc(2030),
    workplaceFqdn: 'alice.twake.example',
  );

  group('DriveIdToken', () {
    test('toString never shows the token or personal claims', () {
      final text = token.toString();

      expect(text, isNot(contains(secret)));
      expect(text, isNot(contains('alice')));
    });

    test('a session that holds it does not show it either', () {
      final session = DriveSession(
        idToken: token,
        platformUrl: Uri.parse('https://stack.example'),
      );

      expect(session.toString(), isNot(contains(secret)));
    });
  });
}
