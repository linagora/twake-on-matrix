import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart' hide CallParticipant;
import 'package:twake_chat/data/datasource/call/matrix_rtc_datasource.dart';
import 'package:twake_chat/data/model/call/sfu_token_response.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/matrix_events/call_event_types.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';

/// How many times the membership lasts its expiry, from when it was sent.
typedef MembershipExpiry = ({int count, int? createdTs});

/// The own membership event of a call: its room and its state key.
typedef _Slot = ({String roomId, String stateKey});

typedef _Attempt = ({_Slot slot, int session});

/// MatrixRTC (MSC4143) session memberships with a LiveKit focus: one
/// `org.matrix.msc3401.call.member` state event per device (DECISION.md D14).
class MatrixRtcDatasourceImpl implements MatrixRtcDatasource {
  MatrixRtcDatasourceImpl(this._maybeClient);

  static const MembershipExpiry firstExpiry = (count: 1, createdTs: null);

  static const memberEventType = CallEventTypes.callMember;
  static const _membershipExpiry = Duration(hours: 4);
  static const _delayedLeave = Duration(seconds: 8);
  static const _delayedLeaveRestart = Duration(seconds: 5);
  static const _expiryHeadroom = Duration(minutes: 1);
  static const _extendRetry = Duration(seconds: 30);
  static const _tokenTimeout = Duration(seconds: 20);
  static final _unprefixedRoomVersion = RegExp(
    r'^org\.matrix\.msc(3757|3779)\b',
  );

  final Client? _maybeClient;
  String? _delayId;
  Future<void> Function()? _resendMembership;
  Future<void>? _restarting;
  var _session = 0;
  Timer? _restartTimer;
  Timer? _expiryTimer;
  Timer? _extendRetryTimer;
  Map<String, Object?>? _extension;
  Future<void>? _extending;

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

  @visibleForTesting
  static Map<String, Object?> membershipContent(
    CallDevice device,
    CallJoin join, [
    MembershipExpiry expiry = firstExpiry,
  ]) => {
    'application': 'm.call',
    'call_id': '',
    'scope': 'm.room',
    'device_id': device.deviceId,
    'membershipID': '${device.userId}:${device.deviceId}',
    'expires': _membershipExpiry.inMilliseconds * expiry.count,
    'm.call.intent': join.isVideo ? 'video' : 'audio',
    'focus_active': {'type': 'livekit', 'focus_selection': 'oldest_membership'},
    'foci_preferred': [
      {'type': 'livekit', 'livekit_service_url': join.serviceUrl},
    ],
    'created_ts': ?expiry.createdTs,
  };

  @visibleForTesting
  static CallServer parseServer(http.Response response) {
    if (response.statusCode ~/ 100 != 2) {
      throw CallTokenFailedException(cause: 'HTTP ${response.statusCode}');
    }
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const CallTokenFailedException(cause: 'Unexpected body');
    }
    final token = SfuTokenResponse.fromJson(json);
    final url = token.url;
    final jwt = token.jwt;
    if (url == null || jwt == null) {
      throw const CallTokenFailedException(cause: 'No url or jwt');
    }
    return CallServer(url: url, token: jwt);
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
  ({String? displayName, Uri? avatarUrl}) memberProfile(
    CallRoom call,
    CallParticipant participant,
  ) {
    final user = _maybeClient
        ?.getRoomById(call.id)
        ?.unsafeGetUserFromMemoryOrFallback(participant.userId);
    return (displayName: user?.calcDisplayname(), avatarUrl: user?.avatarUrl);
  }

  @override
  Future<CallServer> fetchServer(CallJoin join) async {
    final client = _client;
    _room(join.room);
    final device = _device;
    try {
      final openIdToken = await client.requestOpenIdToken(device.userId, {});
      final response = await client.httpClient
          .post(
            Uri.parse('${join.serviceUrl}/sfu/get'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'room': join.room.id,
              'openid_token': openIdToken.toJson(),
              'device_id': device.deviceId,
            }),
          )
          .timeout(_tokenTimeout);
      return parseServer(response);
    } on CallException {
      rethrow;
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
    final deviceId = room
        .getState(memberEventType, slot.stateKey)
        ?.content
        .tryGet<String>('device_id');
    if (deviceId == null) return;
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
    try {
      await _write(slot, membershipContent(device, join));
    } on Exception catch (error) {
      _stopTimers();
      throw CallMembershipFailedException(cause: error);
    }
    _resendMembership = () => _write(slot, membershipContent(device, join));
    _extendBeforeExpiry(
      slot,
      (expiry) => membershipContent(device, join, expiry),
    );
  }

  Future<String> _write(_Slot slot, Map<String, Object?> content) =>
      _client.setRoomStateWithKey(
        slot.roomId,
        memberEventType,
        slot.stateKey,
        content,
      );

  /// `expires` grows by its own length before it lapses, from the same
  /// `created_ts`.
  void _extendBeforeExpiry(
    _Slot slot,
    Map<String, Object?> Function(MembershipExpiry expiry) contentFor,
  ) {
    final createdTs = DateTime.now().millisecondsSinceEpoch;
    var count = 1;
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(_membershipExpiry - _expiryHeadroom, (_) {
      count++;
      _extension = contentFor((count: count, createdTs: createdTs));
      _queueExtension(slot);
    });
  }

  /// One write at a time, always the newest content: an older one never
  /// lands last.
  void _queueExtension(_Slot slot) {
    final attempt = (slot: slot, session: _session);
    _extending = (_extending ?? Future<void>.value()).then(
      (_) => _extend(attempt),
    );
  }

  Future<void> _extend(_Attempt attempt) async {
    final content = _extension;
    if (content == null || attempt.session != _session) return;
    try {
      await _write(attempt.slot, content);
    } on Exception catch (error, stackTrace) {
      Logs().w('MatrixRtcDatasource: not extended', error, stackTrace);
      if (attempt.session != _session) return;
      _extendRetryTimer?.cancel();
      _extendRetryTimer = Timer(
        _extendRetry,
        () => _queueExtension(attempt.slot),
      );
    }
  }

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

  String? _stopTimers() {
    _session++;
    _resendMembership = null;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _extendRetryTimer?.cancel();
    _extendRetryTimer = null;
    _extension = null;
    _restartTimer?.cancel();
    _restartTimer = null;
    final delayId = _delayId;
    _delayId = null;
    return delayId;
  }

  @override
  Future<void> leaveMembership(CallRoom call) async {
    final delayId = _stopTimers();
    // A write still in flight would otherwise land after the leave.
    final extending = _extending;
    final restarting = _restarting;
    _extending = null;
    await extending;
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
    // Encrypted during the join, before this listened, or no longer there.
    final room = client.getRoomById(call.id);
    if (room == null || room.encrypted) {
      yield null;
      return;
    }
    yield* client.onTimelineEvent.stream
        .where(
          (event) =>
              event.roomId == call.id && event.type == EventTypes.Encryption,
        )
        .map((_) {});
  }

  void dispose() => _stopTimers();
}
