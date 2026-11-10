import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/repository/call/call_repository.dart';

class JoinCallUseCase {
  const JoinCallUseCase(this._repository);

  final CallRepository _repository;

  static bool _never() => false;

  /// The membership is sent once the media is up, so that the others never
  /// see a device that could not connect. Null when [isCancelled] turns true
  /// before the membership is sent.
  Future<CallRoomInfo?> execute({
    required String roomId,
    required String? serviceUrl,
    required bool isVideo,
    bool Function() isCancelled = _never,
  }) async {
    if (serviceUrl == null) throw const CallServiceUnavailableException();
    final join = CallJoin(
      room: CallRoom(roomId),
      serviceUrl: serviceUrl,
      isVideo: isVideo,
    );
    final room = _repository.getRoomInfo(join.room);
    // DECISION.md D14: a call is encrypted when its room is.
    if (room.isEncrypted) throw const CallEncryptionUnsupportedException();
    // Before the token and the microphone: a member may not hold the state
    // event of the call in a group (power level).
    if (!room.canJoin) throw const CallNoPermissionException();
    await _repository.endStaleOwnMembership(join.room);
    final server = await _repository.fetchServer(join);
    if (isCancelled()) return null;
    await _repository.connectMedia(
      server,
      CallMediaState(isMicrophoneOn: true, isCameraOn: isVideo),
    );
    if (isCancelled()) {
      await _repository.disconnectMedia();
      return null;
    }
    try {
      await _repository.joinMembership(join);
    } on CallException {
      await _repository.disconnectMedia();
      rethrow;
    }
    return room;
  }
}
