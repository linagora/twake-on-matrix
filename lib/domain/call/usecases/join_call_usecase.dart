import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_cancellation.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/repository/call/call_repository.dart';

class JoinCallUseCase {
  const JoinCallUseCase(this._repository);

  final CallRepository _repository;

  /// The membership is sent once the media is up, so that the others never
  /// see a device that could not connect. Null when [cancellation] is
  /// cancelled before the membership is sent.
  Future<CallRoomInfo?> execute({
    required String roomId,
    required String? serviceUrl,
    required bool isVideo,
    CallCancellation? cancellation,
  }) async {
    final cancel = cancellation ?? CallCancellation();
    final join = _joinOf(roomId, serviceUrl: serviceUrl, isVideo: isVideo);
    final room = _checkRoom(join.room);
    await _repository.endStaleOwnMembership(join.room);
    final server = await _repository.fetchServer(join);
    if (cancel.isCancelled) return null;
    // DECISION.md D14: a call is encrypted when its room is.
    final media = CallMediaState(
      isMicrophoneOn: true,
      isCameraOn: join.isVideo,
      isEncrypted: room.isEncrypted,
    );
    if (!await _connect(server, media, cancel)) return null;
    await _sendMembership(join, cancel);
    if (room.isEncrypted && !cancel.isCancelled) {
      _repository.startMediaKeys(join.room);
    }
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
    // Before the token and the microphone: a member may not hold the state
    // event of the call in a group (power level).
    if (!info.canJoin) throw const CallNoPermissionException();
    return info;
  }

  /// False when cancelled while the media connected: it is disconnected
  /// again.
  Future<bool> _connect(
    CallServer server,
    CallMediaState media,
    CallCancellation cancellation,
  ) async {
    await _repository.connectMedia(server, media);
    if (!cancellation.isCancelled) return true;
    await _repository.disconnectMedia();
    return false;
  }

  /// Left meanwhile: the microphone stops at once, the membership ends once
  /// it has been sent.
  Future<void> _sendMembership(
    CallJoin join,
    CallCancellation cancellation,
  ) async {
    final sent = _repository.joinMembership(join);
    try {
      await Future.any([sent, cancellation.whenCancelled]);
      if (!cancellation.isCancelled) return;
      await _repository.disconnectMedia();
      await sent;
    } on CallException {
      await _repository.disconnectMedia();
      rethrow;
    }
  }
}
