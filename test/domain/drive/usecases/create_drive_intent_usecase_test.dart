import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/entities/drive_intent.dart';
import 'package:twake_chat/domain/drive/entities/drive_picker_options.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/drive/sources/drive_intent_source.dart';
import 'package:twake_chat/domain/drive/usecases/create_drive_intent_usecase.dart';

class _Source implements DriveIntentSource {
  _Source(this.answer);

  final Future<DriveIntent> Function() answer;
  DriveSession? session;
  DrivePickerOptions? options;

  @override
  Future<DriveIntent> createIntent({
    required DriveSession session,
    required Future<DriveSession> Function() renewSession,
    required DrivePickerOptions options,
  }) {
    this.session = session;
    this.options = options;
    return answer();
  }
}

void main() {
  final session = DriveSession(
    idToken: DriveIdToken(value: 'id', expiresAt: DateTime.utc(2100)),
    platformUrl: Uri.parse('https://alice.twake.example'),
  );
  const options = DrivePickerOptions(linkLabel: 'Link', darkTheme: false);

  test('asks the source for the intent of the session', () async {
    final source = _Source(
      () async => throw StateError('no intent in this test'),
    );

    await expectLater(
      CreateDriveIntentUseCase(source).execute(
        session: session,
        renewSession: () async => session,
        options: options,
      ),
      throwsStateError,
    );
    expect(source.session, session);
    expect(source.options, options);
  });

  test('lets the failure of the source through', () async {
    final source = _Source(() async => throw Exception('refused'));

    await expectLater(
      CreateDriveIntentUseCase(source).execute(
        session: session,
        renewSession: () async => session,
        options: options,
      ),
      throwsException,
    );
  });
}
