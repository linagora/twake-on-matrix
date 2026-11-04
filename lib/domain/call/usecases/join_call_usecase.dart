import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/repository/call/call_repository.dart';

class JoinCallUseCase {
  const JoinCallUseCase(this._repository);

  final CallRepository _repository;

  /// The membership is sent once the media is up, so that the others never
  /// see a device that could not connect.
  Future<CallRoomInfo> execute({
    required String roomId,
    required String? serviceUrl,
    required bool isVideo,
  }) async {
    if (serviceUrl == null) throw const CallServiceUnavailableException();
    final room = _repository.getRoomInfo(roomId);
    // DECISION.md D10: a call is encrypted when its room is.
    if (room.isEncrypted) throw const CallEncryptionUnsupportedException();
    await _repository.endStaleOwnMembership(roomId);
    final server = await _repository.fetchServer(
      roomId: roomId,
      serviceUrl: serviceUrl,
    );
    await _repository.connectMedia(
      server,
      isMicrophoneOn: true,
      isCameraOn: isVideo,
    );
    try {
      await _repository.joinMembership(
        roomId: roomId,
        serviceUrl: serviceUrl,
        isVideo: isVideo,
      );
    } on CallException {
      await _repository.disconnectMedia();
      rethrow;
    }
    return room;
  }
}
