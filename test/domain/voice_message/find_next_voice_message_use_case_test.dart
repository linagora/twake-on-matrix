import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/voice_message/entities/shown_message.dart';
import 'package:twake_chat/domain/voice_message/exceptions/voice_message_exception.dart';
import 'package:twake_chat/domain/voice_message/repositories/voice_message_repository.dart';
import 'package:twake_chat/domain/voice_message/usecases/find_next_voice_message_use_case.dart';

class _Repository implements VoiceMessageRepository {
  _Repository({this.next, this.error});

  final String? next;
  final Object? error;
  var asked = 0;

  @override
  Future<String?> nextVoiceMessageId({
    required String roomId,
    required String eventId,
    String? threadRootId,
  }) async {
    asked++;
    if (error case final error?) throw error;
    return next;
  }
}

ShownMessage _voice(String id) =>
    ShownMessage(eventId: id, isVoiceMessage: true);
ShownMessage _text(String id) =>
    ShownMessage(eventId: id, isVoiceMessage: false);

void main() {
  test(
    'takes the next message the screen shows when it is a voice one',
    () async {
      final repository = _Repository(next: 'stored');
      final useCase = FindNextVoiceMessageUseCase(repository);

      final next = await useCase.execute(
        roomId: '!r',
        eventId: 'v1',
        shown: [_voice('v1'), _voice('v2')],
      );

      expect(next, 'v2');
      expect(repository.asked, 0);
    },
  );

  test('stops at a shown message that is not a voice one', () async {
    final useCase = FindNextVoiceMessageUseCase(_Repository(next: 'stored'));

    final next = await useCase.execute(
      roomId: '!r',
      eventId: 'v1',
      shown: [_voice('v1'), _text('t')],
    );

    expect(next, isNull);
  });

  test('does not chain from a shown message that is not a voice one', () async {
    final useCase = FindNextVoiceMessageUseCase(_Repository(next: 'stored'));

    final next = await useCase.execute(
      roomId: '!r',
      eventId: 'song',
      shown: [_text('song'), _voice('v1')],
    );

    expect(next, isNull);
  });

  test(
    'reads the repository when the screen does not show the message',
    () async {
      final useCase = FindNextVoiceMessageUseCase(_Repository(next: 'v2'));

      expect(
        await useCase.execute(
          roomId: '!r',
          eventId: 'v1',
          shown: [_voice('x')],
        ),
        'v2',
      );
    },
  );

  test('wraps an exception of the repository in its exception', () async {
    final useCase = FindNextVoiceMessageUseCase(
      _Repository(error: Exception('db')),
    );

    await expectLater(
      useCase.execute(roomId: '!r', eventId: 'v1'),
      throwsA(isA<FindNextVoiceMessageException>()),
    );
  });

  test('lets an error of the repository through', () async {
    final useCase = FindNextVoiceMessageUseCase(
      _Repository(error: StateError('db')),
    );

    await expectLater(
      useCase.execute(roomId: '!r', eventId: 'v1'),
      throwsA(isA<StateError>()),
    );
  });
}
