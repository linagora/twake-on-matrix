import 'package:twake_chat/data/model/call/sfu_token_request.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';
import 'package:twake_chat/domain/model/call/call_ring.dart';

abstract class MatrixRtcDatasource {
  CallRoomInfo getRoomInfo(CallRoom room);

  ({String? displayName, Uri? avatarUrl}) getMemberProfile(
    CallRoom room,
    CallParticipant participant,
  );

  /// What the token service needs to let this device into the call of [room].
  Future<SfuTokenRequest> createTokenRequest(CallRoom room);

  Future<void> endStaleOwnMembership(CallRoom room);

  /// The membership stays alive (delayed leave, expiry) until
  /// [leaveMembership]. Gives the id of the membership event.
  Future<String> joinMembership(CallJoin join);

  /// Whether someone else than this account is in the call of [room].
  bool hasOtherMembers(CallRoom room);

  /// Rings the others of the room (MSC4075), in the clear, for the call
  /// joined with the membership [membershipEventId].
  Future<void> sendRing(CallJoin join, {required String membershipEventId});

  /// Tells the other devices of the account, and the caller, that the account
  /// does not take the call (MSC4310).
  Future<void> declineRing(CallRing ring);

  /// The rings that ring now, on each change.
  Stream<List<CallRing>> watchRings();

  Stream<MissedCall> watchMissedCalls();

  /// Makes the push of a ring ring (sound), by two underride push rules.
  Future<void> ensureCallRingPushRules();

  Future<void> leaveMembership(CallRoom room);

  /// Emits when encryption is turned on in [room]; fails with
  /// `CallRoomNotFoundException` once the account is no longer in it.
  Stream<void> watchRoomEncrypted(CallRoom room);
}
