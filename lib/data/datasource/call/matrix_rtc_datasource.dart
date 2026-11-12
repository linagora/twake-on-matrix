import 'package:twake_chat/data/model/call/sfu_token_request.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';

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
  /// [leaveMembership].
  Future<void> joinMembership(CallJoin join);

  Future<void> leaveMembership(CallRoom room);

  /// Emits when encryption is turned on in [room]; fails with
  /// `CallRoomNotFoundException` once the account is no longer in it.
  Stream<void> watchRoomEncrypted(CallRoom room);
}
