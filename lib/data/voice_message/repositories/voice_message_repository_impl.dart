import 'package:twake_chat/data/voice_message/datasources/voice_message_datasource.dart';
import 'package:twake_chat/domain/voice_message/repositories/voice_message_repository.dart';

class VoiceMessageRepositoryImpl implements VoiceMessageRepository {
  const VoiceMessageRepositoryImpl(this._datasource);

  final VoiceMessageDatasource _datasource;

  @override
  Future<String?> nextVoiceMessageId({
    required String roomId,
    required String eventId,
    String? threadRootId,
  }) => _datasource.nextVoiceMessageId(
    roomId: roomId,
    eventId: eventId,
    threadRootId: threadRootId,
  );
}
