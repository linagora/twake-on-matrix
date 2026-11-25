import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/domain/scribe/sources/scribe_source.dart';
import 'package:twake_chat/domain/scribe/usecases/rewrite_draft_usecase.dart';
import 'package:twake_chat/domain/scribe/usecases/rewrite_draft_usecase.provider.dart';
import 'package:twake_chat/pages/scribe/scribe_controller.dart';

const _roomId = '!room:example.com';
const _room = ScribeRoom(
  isEncrypted: false,
  isDirect: false,
  scribeEnabled: false,
);

class _Source implements ScribeSource {
  Completer<String> answer = Completer();

  @override
  Future<String> rewrite({
    required DriveSession session,
    required Future<DriveSession> Function() renewSession,
    required ScribePrompt prompt,
    required String draft,
  }) => answer.future;
}

void main() {
  final session = DriveSession(
    idToken: DriveIdToken(value: 'id', expiresAt: DateTime.utc(2100)),
    platformUrl: Uri.parse('https://alice.twake.example'),
  );
  late _Source source;
  late ProviderContainer container;
  late ProviderSubscription<bool> isRewriting;

  setUp(() {
    source = _Source();
    container = ProviderContainer.test(
      overrides: [
        rewriteDraftUseCaseProvider.overrideWithValue(
          RewriteDraftUseCase(
            source: source,
            obtainSession: () async => session,
            renewSession: () async => session,
            currentAccount: () => '@alice:example.com',
          ),
        ),
      ],
    );
    isRewriting = container.listen(
      scribeControllerProvider(_roomId),
      (_, _) {},
    );
  });

  Future<String> rewrite() => container
      .read(scribeControllerProvider(_roomId).notifier)
      .rewrite(room: _room, prompt: ScribePrompt.summarize, draft: 'text');

  test('is busy while the draft is rewritten, idle after', () async {
    final result = rewrite();
    expect(isRewriting.read(), isTrue);

    source.answer.complete('summary');

    expect(await result, 'summary');
    expect(isRewriting.read(), isFalse);
  });

  test('is idle again after a failure, which reaches the caller', () async {
    final result = rewrite();
    source.answer.completeError(const ScribeRewriteFailed());

    await expectLater(result, throwsA(isA<ScribeRewriteFailed>()));
    expect(isRewriting.read(), isFalse);
  });

  test('a controller disposed meanwhile still hands back the result', () async {
    final result = rewrite();
    // The app went away during the rewrite.
    container.dispose();

    source.answer.complete('summary');

    expect(await result, 'summary');
  });

  test('refuses a second rewrite while one runs', () async {
    final first = rewrite();

    expect(rewrite, throwsStateError);

    source.answer.complete('summary');
    await first;
  });
}
