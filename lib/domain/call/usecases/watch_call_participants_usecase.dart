import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';
import 'package:twake_chat/domain/repository/call/call_repository.dart';

class WatchCallParticipantsUseCase {
  const WatchCallParticipantsUseCase(this._repository);

  final CallRepository _repository;

  Stream<List<CallParticipant>> execute(String roomId) =>
      _repository.watchParticipants(CallRoom(roomId));
}
