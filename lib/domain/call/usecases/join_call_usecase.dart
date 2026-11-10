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
    final join = _joinOf(roomId, serviceUrl: serviceUrl, isVideo: isVideo);
    final room = _checkRoom(join.room);
    await _repository.endStaleOwnMembership(join.room);
    final server = await _repository.fetchServer(join);
    if (isCancelled()) return null;
    if (!await _connect(server, join, isCancelled)) return null;
    await _sendMembership(join);
    return room;
  }

  static CallJoin _joinOf(
    String roomId, {
    required String? serviceUrl,
    required bool isVideo,
  }) {
    if (serviceUrl == null) throw const CallServiceUnavailableException();
    return CallJoin(
      room: CallRoom(roomId),
      serviceUrl: serviceUrl,
      isVideo: isVideo,
    );
  }

  CallRoomInfo _checkRoom(CallRoom room) {
    final info = _repository.getRoomInfo(room);
    // DECISION.md D14: a call is encrypted when its room is.
    if (info.isEncrypted) throw const CallEncryptionUnsupportedException();
    // Before the token and the microphone: a member may not hold the state
    // event of the call in a group (power level).
    if (!info.canJoin) throw const CallNoPermissionException();
    return info;
  }

  /// False when cancelled while the media connected: it is disconnected
  /// again.
  Future<bool> _connect(
    CallServer server,
    CallJoin join,
    bool Function() isCancelled,
  ) async {
    await _repository.connectMedia(
      server,
      CallMediaState(isMicrophoneOn: true, isCameraOn: join.isVideo),
    );
    if (!isCancelled()) return true;
    await _repository.disconnectMedia();
    return false;
  }

  Future<void> _sendMembership(CallJoin join) async {
    try {
      await _repository.joinMembership(join);
    } on CallException {
      await _repository.disconnectMedia();
      rethrow;
    }
  }
}
