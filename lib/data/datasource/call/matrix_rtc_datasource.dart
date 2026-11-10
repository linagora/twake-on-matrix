import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';

abstract class MatrixRtcDatasource {
  CallRoomInfo getRoomInfo(CallRoom room);

  ({String? displayName, Uri? avatarUrl}) memberProfile(
    CallRoom room,
    CallParticipant participant,
  );

  Future<CallServer> fetchServer(CallJoin join);

  Future<void> endStaleOwnMembership(CallRoom room);

  /// The membership stays alive (delayed leave, expiry) until
  /// [leaveMembership].
  Future<void> joinMembership(CallJoin join);

  Future<void> leaveMembership(CallRoom room);

  /// Emits when encryption is turned on in [room].
  Stream<void> watchRoomEncrypted(CallRoom room);
}
