import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/voice_message/exceptions/voice_message_exception.dart';
import 'package:twake_chat/domain/voice_message/repositories/voice_message_repository.dart';
import 'package:twake_chat/domain/voice_message/usecases/find_next_voice_message_use_case.dart';

class _Repository implements VoiceMessageRepository {
  _Repository({this.next, this.error});

  final String? next;
  final Object? error;

  @override
  Future<String?> nextVoiceMessageId({
    required String roomId,
    required String eventId,
  }) async {
    if (error != null) throw error!;
    return next;
  }
}

void main() {
  test('returns the next voice message of the repository', () async {
    final useCase = FindNextVoiceMessageUseCase(_Repository(next: 'v2'));

    expect(await useCase.execute(roomId: '!r', eventId: 'v1'), 'v2');
  });

  test('wraps a failure of the repository in its exception', () async {
    final useCase = FindNextVoiceMessageUseCase(
      _Repository(error: StateError('db')),
    );

    await expectLater(
      useCase.execute(roomId: '!r', eventId: 'v1'),
      throwsA(isA<FindNextVoiceMessageException>()),
    );
  });
}
