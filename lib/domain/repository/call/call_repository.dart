import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';
import 'package:twake_chat/domain/model/call/call_ring.dart';

/// All failures are `CallException`s.
abstract class CallRepository {
  CallRoomInfo getRoomInfo(CallRoom room);

  Future<CallServer> fetchServer(CallJoin join);

  /// Ends a membership of this device left by an earlier run.
  Future<void> endStaleOwnMembership(CallRoom room);

  /// Gives the id of the membership event.
  Future<String> joinMembership(CallJoin join);

  /// Whether someone else than this account is in the call of [room].
  bool hasOtherMembers(CallRoom room);

  Future<void> sendRing(CallJoin join, {required String membershipEventId});

  Future<void> declineRing(CallRing ring);

  /// The rings that ring now, on each change.
  Stream<List<CallRing>> watchRings();

  Stream<MissedCall> watchMissedCalls();

  Future<void> ensureCallRingPushRules();

  Future<void> leaveMembership(CallRoom room);

  Future<void> connectMedia(CallServer server, CallMediaState media);

  Future<void> disconnectMedia();

  Future<void> setMicrophone({required bool isOn});

  /// Emits when encryption is turned on in [room].
  Stream<void> watchRoomEncrypted(CallRoom room);

  /// Emits the participants on each change while the media is connected.
  Stream<List<CallParticipant>> watchParticipants(CallRoom room);
}
