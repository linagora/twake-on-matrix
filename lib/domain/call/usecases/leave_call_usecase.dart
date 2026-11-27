import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/repository/call/call_repository.dart';

class LeaveCallUseCase {
  const LeaveCallUseCase(this._repository);

  final CallRepository _repository;

  Future<void> execute(String roomId) async {
    final room = CallRoom(roomId);
    _repository.closeCall(room, endedAt: DateTime.now());
    // The microphone stops first, however slow the homeserver is.
    try {
      await _repository.disconnectMedia();
    } finally {
      try {
        await _repository.stopMediaKeys();
        await _repository.leaveMembership(room);
      } finally {
        await _sendLine(room);
      }
    }
  }

  /// A line not written is a call with no line in the chat.
  Future<void> _sendLine(CallRoom room) async {
    try {
      await _repository.sendCallLine(room);
    } on CallException {
      // The data layer logs it.
    }
  }
}
