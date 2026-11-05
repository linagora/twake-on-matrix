import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart' hide CallParticipant;
import 'package:twake_chat/data/datasource/call/matrix_rtc_datasource.dart';
import 'package:twake_chat/data/datasource_impl/call/call_membership_extender.dart';
import 'package:twake_chat/data/datasource_impl/call/matrix_rtc_media_keys.dart';
import 'package:twake_chat/data/model/call/call_member_content.dart';
import 'package:twake_chat/data/model/call/sfu_token_request.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/matrix_events/call_event_types.dart';
import 'package:twake_chat/domain/model/call/call_media_key.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';

/// The own membership event of a call: its room and its state key.
typedef _Slot = ({String roomId, String stateKey});

/// MatrixRTC (MSC4143) session memberships with a LiveKit focus: one
/// `org.matrix.msc3401.call.member` state event per device (DECISION.md D14).
class MatrixRtcDatasourceImpl implements MatrixRtcDatasource {
  MatrixRtcDatasourceImpl(this._maybeClient);

  static const memberEventType = CallEventTypes.callMember;
  static const _delayedLeave = Duration(seconds: 8);
  static const _delayedLeaveRestart = Duration(seconds: 5);
  static final _unprefixedRoomVersion = RegExp(
    r'^org\.matrix\.msc(3757|3779)\b',
  );

  final Client? _maybeClient;
  String? _delayId;
  Future<void> Function()? _resendMembership;
  Future<void>? _restarting;
  var _session = 0;
  Timer? _restartTimer;
  CallMembershipExtender? _extender;

  Client get _client => _maybeClient ?? (throw const CallNoClientException());

  CallDevice get _device => CallDevice(
    userId: _client.userID ?? (throw const CallNoClientException()),
    deviceId: _client.deviceID ?? (throw const CallNoClientException()),
  );

  Room _room(CallRoom call) {
    final room = _client.getRoomById(call.id);
    if (room == null || room.membership != Membership.join) {
      throw const CallRoomNotFoundException();
    }
    return room;
  }

  @visibleForTesting
  static String stateKeyFor(CallDevice device, {required String? roomVersion}) {
    final stateKey = '${device.userId}_${device.deviceId}_m.call';
    final isUnprefixed =
        roomVersion != null && _unprefixedRoomVersion.hasMatch(roomVersion);
    return isUnprefixed ? stateKey : '_$stateKey';
  }

  _Slot _ownSlot(Room room) => (
    roomId: room.id,
    stateKey: stateKeyFor(_device, roomVersion: room.roomVersion),
  );

  @override
  CallRoomInfo getRoomInfo(CallRoom call) {
    final room = _room(call);
    return CallRoomInfo(
      isEncrypted: room.encrypted,
      isDirect: room.isDirectChat,
      canJoin: room.canChangeStateEvent(memberEventType),
    );
  }

  @override
  ({String? displayName, Uri? avatarUrl}) getMemberProfile(
    CallRoom call,
    CallParticipant participant,
  ) {
    final user = _maybeClient
        ?.getRoomById(call.id)
        ?.unsafeGetUserFromMemoryOrFallback(participant.userId);
    return (displayName: user?.calcDisplayname(), avatarUrl: user?.avatarUrl);
  }

  @override
  Future<SfuTokenRequest> createTokenRequest(CallRoom call) async {
    final client = _client;
    _room(call);
    final device = _device;
    try {
      final openIdToken = await client.requestOpenIdToken(device.userId, {});
      return SfuTokenRequest(
        room: call.id,
        openidToken: openIdToken.toJson(),
        deviceId: device.deviceId,
      );
    } on Exception catch (error) {
      throw CallTokenFailedException(cause: error);
    }
  }

  @override
  Future<void> endStaleOwnMembership(CallRoom call) async {
    final room = _room(call);
    try {
      await room.postLoad();
    } on Exception catch (error) {
      throw CallMembershipFailedException(cause: error);
    }
    final slot = _ownSlot(room);
    final content = room.getState(memberEventType, slot.stateKey)?.content;
    if (content == null) return;
    if (CallMemberContent.fromJson(content).deviceId == null) return;
    try {
      await _write(slot, {});
    } on Exception catch (error, stackTrace) {
      Logs().w('MatrixRtcDatasource: stale membership kept', error, stackTrace);
    }
  }

  @override
  Future<void> joinMembership(CallJoin join) async {
    final room = _room(join.room);
    if (!room.canChangeStateEvent(memberEventType)) {
      throw const CallNoPermissionException();
    }
    final slot = _ownSlot(room);
    final device = _device;
    await _scheduleDelayedLeave(slot);
    final String eventId;
    try {
      eventId = await _write(
        slot,
        CallMemberContent.forJoin(device, join).toJson(),
      );
    } on Exception catch (error) {
      _endSession().extended.ignore();
      throw CallMembershipFailedException(cause: error);
    }
    _resendMembership = () =>
        _write(slot, CallMemberContent.forJoin(device, join).toJson());
    _extender = CallMembershipExtender((content) => _write(slot, content))
      ..start(
        (expiry) => CallMemberContent.forJoin(device, join, expiry).toJson(),
        createdTs: _serverTimeOf(slot.roomId, eventId),
      );
  }

  /// The others count the expiry from it, not from the clock of this device.
  Future<int> _serverTimeOf(String roomId, String eventId) async {
    try {
      final event = await _client.getOneRoomEvent(roomId, eventId);
      return event.originServerTs.millisecondsSinceEpoch;
    } on Exception catch (error, stackTrace) {
      Logs().w('MatrixRtcDatasource: no server time', error, stackTrace);
      return DateTime.now().millisecondsSinceEpoch;
    }
  }

  Future<String> _write(_Slot slot, Map<String, Object?> content) =>
      _client.setRoomStateWithKey(
        slot.roomId,
        memberEventType,
        slot.stateKey,
        content,
      );

  /// The homeserver ends the membership itself if this device vanishes
  /// (MSC4140); without delayed events the membership expires instead.
  Future<void> _scheduleDelayedLeave(_Slot slot) async {
    final session = _session;
    final String delayId;
    try {
      delayId = await _client.setRoomStateWithKeyWithDelay(
        slot.roomId,
        memberEventType,
        slot.stateKey,
        _delayedLeave.inMilliseconds,
        {},
      );
    } on Exception catch (error, stackTrace) {
      Logs().w('MatrixRtcDatasource: no delayed leave', error, stackTrace);
      return;
    }
    if (session != _session) {
      unawaited(
        _client
            .manageDelayedEvent(delayId, DelayedEventAction.cancel)
            .catchError(
              (Object error, StackTrace stackTrace) => Logs().w(
                'MatrixRtcDatasource: delayed leave not cancelled',
                error,
                stackTrace,
              ),
            ),
      );
      return;
    }
    _delayId = delayId;
    _restartTimer?.cancel();
    _restartTimer = Timer.periodic(_delayedLeaveRestart, (_) {
      if (_restarting != null) return;
      _restarting = _restartDelayedLeave(
        slot,
      ).whenComplete(() => _restarting = null);
    });
  }

  Future<void> _restartDelayedLeave(_Slot slot) async {
    final delayId = _delayId;
    if (delayId == null) return;
    final session = _session;
    try {
      await _client.manageDelayedEvent(delayId, DelayedEventAction.restart);
    } on MatrixException catch (error) {
      // Left meanwhile: the leave consumed the delayed event.
      if (error.error != MatrixError.M_NOT_FOUND || _delayId != delayId) return;
      // Paused too long: the homeserver ended the membership.
      await _scheduleDelayedLeave(slot);
      if (session != _session) return;
      await _resendMembership?.call().catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        Logs().w('MatrixRtcDatasource: not sent again', error, stackTrace);
      });
    } on Exception catch (error, stackTrace) {
      Logs().w('MatrixRtcDatasource: restart failed', error, stackTrace);
    }
  }

  ({String? delayId, Future<void> extended}) _endSession() {
    _session++;
    _resendMembership = null;
    final extended = _extender?.stop() ?? Future<void>.value();
    _extender = null;
    _restartTimer?.cancel();
    _restartTimer = null;
    final delayId = _delayId;
    _delayId = null;
    return (delayId: delayId, extended: extended);
  }

  @override
  Future<void> leaveMembership(CallRoom call) async {
    final (:delayId, :extended) = _endSession();
    // A write still in flight would otherwise land after the leave.
    final restarting = _restarting;
    await extended;
    await restarting;
    if (delayId != null) {
      try {
        await _client.manageDelayedEvent(delayId, DelayedEventAction.send);
        return;
      } on Exception catch (error, stackTrace) {
        Logs().w('MatrixRtcDatasource: delayed leave', error, stackTrace);
      }
    }
    final room = _room(call);
    try {
      await _write(_ownSlot(room), {});
    } on Exception catch (error) {
      throw CallMembershipFailedException(cause: error);
    }
  }

  @override
  Stream<void> watchRoomEncrypted(CallRoom call) async* {
    final client = _maybeClient;
    if (client == null) return;
    // Encrypted during the join, before this listened.
    var isEncrypted = _isEncryptedJoined(client, call);
    if (isEncrypted) yield null;
    // The state block of a limited sync never reaches onTimelineEvent. Watches
    // on once encrypted: the call of an encrypted room still ends with it.
    await for (final _ in client.onSync.stream) {
      if (!_isEncryptedJoined(client, call) || isEncrypted) continue;
      isEncrypted = true;
      yield null;
    }
  }

  /// Throws once this account left the room or was removed from it.
  static bool _isEncryptedJoined(Client client, CallRoom call) {
    final room = client.getRoomById(call.id);
    if (room == null || room.membership != Membership.join) {
      throw const CallRoomNotFoundException();
    }
    return room.encrypted;
  }

  @override
  Stream<CallMediaKey> watchMediaKeys(CallRoom call) {
    _room(call);
    return MatrixRtcMediaKeys(_client, call.id, memberEventType).run();
  }

  void dispose() => _endSession().extended.ignore();
}
