import 'package:twake_chat/domain/repository/call/call_repository.dart';

class LeaveCallUseCase {
  const LeaveCallUseCase(this._repository);

  final CallRepository _repository;

  Future<void> execute(String roomId) async {
    try {
      await _repository.leaveMembership(roomId);
    } finally {
      await _repository.disconnectMedia();
    }
  }
}
