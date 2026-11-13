import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/repository/call/call_repository.dart';

class LeaveCallUseCase {
  const LeaveCallUseCase(this._repository);

  final CallRepository _repository;

  Future<void> execute(String roomId) async {
    // The microphone stops first, however slow the homeserver is.
    try {
      await _repository.disconnectMedia();
    } finally {
      await _repository.stopMediaKeys();
      await _repository.leaveMembership(CallRoom(roomId));
    }
  }
}
