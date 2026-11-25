import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/domain/scribe/sources/scribe_source.dart';
import 'package:twake_chat/domain/scribe/usecases/rewrite_draft_usecase.dart';

class _Source implements ScribeSource {
  final calls = <({DriveSession session, ScribePrompt prompt, String draft})>[];

  @override
  Future<String> rewrite({
    required DriveSession session,
    required Future<DriveSession> Function() renewSession,
    required ScribePrompt prompt,
    required String draft,
  }) async {
    calls.add((session: session, prompt: prompt, draft: draft));
    return 'rewritten';
  }
}

const _clearRoom = ScribeRoom(
  isEncrypted: false,
  isDirect: false,
  scribeEnabled: false,
);

void main() {
  final session = DriveSession(
    idToken: DriveIdToken(value: 'id', expiresAt: DateTime.utc(2100)),
    platformUrl: Uri.parse('https://alice.twake.example'),
  );
  late _Source source;
  late int obtained;
  late Future<DriveSession> Function() obtain;
  late RewriteDraftUseCase useCase;

  setUp(() {
    source = _Source();
    obtained = 0;
    obtain = () async {
      obtained++;
      return session;
    };
    useCase = RewriteDraftUseCase(
      source: source,
      obtainSession: () => obtain(),
      renewSession: () async => session,
    );
  });

  test('signs in, then sends the whole draft with the prompt', () async {
    final text = await useCase.execute(
      room: _clearRoom,
      prompt: ScribePrompt.translateEnglish,
      draft: '  Bonjour\nà tous  ',
    );

    expect(text, 'rewritten');
    expect(obtained, 1);
    expect(source.calls.single.session, session);
    expect(source.calls.single.prompt, ScribePrompt.translateEnglish);
    expect(source.calls.single.draft, '  Bonjour\nà tous  ');
  });

  test(
    'refuses a room that does not offer it, before signing in or sending',
    () async {
      await expectLater(
        useCase.execute(
          room: const ScribeRoom(
            isEncrypted: true,
            isDirect: false,
            scribeEnabled: false,
          ),
          prompt: ScribePrompt.correctGrammar,
          draft: 'secret',
        ),
        throwsA(isA<ScribeNotOffered>()),
      );
      expect(obtained, 0);
      expect(source.calls, isEmpty);
    },
  );

  test('refuses a blank draft, before signing in or sending', () async {
    await expectLater(
      useCase.execute(
        room: _clearRoom,
        prompt: ScribePrompt.summarize,
        draft: ' \n\t',
      ),
      throwsA(isA<ScribeEmptyDraft>()),
    );
    expect(obtained, 0);
    expect(source.calls, isEmpty);
  });

  test('a failed sign-in sends nothing', () async {
    obtain = () async => throw const DriveSignInCancelled();

    await expectLater(
      useCase.execute(
        room: _clearRoom,
        prompt: ScribePrompt.summarize,
        draft: 'text',
      ),
      throwsA(isA<DriveSignInCancelled>()),
    );
    expect(source.calls, isEmpty);
  });
}
