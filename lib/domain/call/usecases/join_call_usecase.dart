import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_cancellation.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/repository/call/call_repository.dart';

class JoinCallUseCase {
  const JoinCallUseCase(this._repository);

  final CallRepository _repository;

  /// The membership is sent once the media is up, so that the others never
  /// see a device that could not connect. Null when [cancellation] is
  /// cancelled before the membership is sent. The others ring once it is
  /// sent, unless someone is already in the call.
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
    final othersInCall = await _hasOthers(join.room);
    // Before the membership: the others send their keys once they see it.
    if (room.isEncrypted) _repository.startMediaKeys(join.room);
    final membershipEventId = await _sendMembership(
      join,
      cancel,
      sharesKeys: room.isEncrypted,
    );
    if (membershipEventId != null && !othersInCall) {
      await _ring(join, membershipEventId);
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
  /// it has been sent. Gives the id of the membership event, null when left.
  Future<String?> _sendMembership(
    CallJoin join,
    CallCancellation cancellation, {
    required bool sharesKeys,
  }) async {
    final sent = _repository.joinMembership(join);
    try {
      await Future.any([sent, cancellation.whenCancelled]);
      if (!cancellation.isCancelled) return await sent;
      await _stopMedia(sharesKeys: sharesKeys);
      await sent;
      return null;
    } on CallException {
      await _stopMedia(sharesKeys: sharesKeys);
      rethrow;
    }
  }

  Future<void> _stopMedia({required bool sharesKeys}) async {
    await _repository.disconnectMedia();
    if (sharesKeys) await _repository.stopMediaKeys();
  }

  /// A room that cannot be read leaves no call to join: the media stops.
  Future<bool> _hasOthers(CallRoom room) async {
    try {
      return _repository.hasOtherMembers(room);
    } on CallException {
      await _repository.disconnectMedia();
      rethrow;
    }
  }

  /// A ring that cannot be sent leaves the call going. The data layer logs it.
  Future<void> _ring(CallJoin join, String membershipEventId) async {
    try {
      await _repository.sendRing(join, membershipEventId: membershipEventId);
    } on Exception {
      // Only the ring is lost.
    }
  }
}
