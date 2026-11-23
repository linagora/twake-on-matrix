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

  /// Emits when someone else declines the last ring this device sent in
  /// [room].
  Stream<void> watchRingDeclined(CallRoom room);

  Future<void> declineRing(CallRing ring);

  /// The rings that ring now, on each change.
  Stream<List<CallRing>> watchRings();

  Stream<MissedCall> watchMissedCalls();

  Future<void> ensureCallRingPushRules();

  Future<void> leaveMembership(CallRoom room);

  Future<void> connectMedia(CallServer server, CallMediaState media);

  /// Shares the media keys of an encrypted call until [stopMediaKeys].
  void startMediaKeys(CallRoom room);

  Future<void> stopMediaKeys();

  Future<void> disconnectMedia();

  Future<void> setMicrophone({required bool isOn});

  Future<void> setCamera({required bool isOn});

  /// Off, the audio goes to the headset when one is connected, else to the
  /// earpiece. [isForced] keeps the speaker on over a headset.
  Future<void> setSpeaker({required bool isOn, required bool isForced});

  /// Emits when encryption is turned on in [room].
  Stream<void> watchRoomEncrypted(CallRoom room);

  /// Emits the participants on each change while the media is connected.
  Stream<List<CallParticipant>> watchParticipants(CallRoom room);
}
