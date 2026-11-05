import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';

/// All failures are `CallException`s.
abstract class CallRepository {
  CallRoomInfo getRoomInfo(CallRoom room);

  Future<CallServer> fetchServer(CallJoin join);

  /// Ends a membership of this device left by an earlier run.
  Future<void> endStaleOwnMembership(CallRoom room);

  Future<void> joinMembership(CallJoin join);

  Future<void> leaveMembership(CallRoom room);

  Future<void> connectMedia(CallServer server, CallMediaState media);

  /// Shares the media keys of an encrypted call until [stopMediaKeys].
  void startMediaKeys(CallRoom room);

  Future<void> stopMediaKeys();

  Future<void> disconnectMedia();

  Future<void> setMicrophone({required bool isOn});

  /// Emits when encryption is turned on in [room].
  Stream<void> watchRoomEncrypted(CallRoom room);

  /// Emits the participants on each change while the media is connected.
  Stream<List<CallParticipant>> watchParticipants(CallRoom room);
}
