import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource/call/matrix_rtc_datasource.dart';
import 'package:twake_chat/data/model/call/sfu_token_response.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';

/// MatrixRTC (MSC4143) session memberships with a LiveKit focus: one
/// `org.matrix.msc3401.call.member` state event per device (DECISION.md D14).
class MatrixRtcDatasourceImpl implements MatrixRtcDatasource {
  MatrixRtcDatasourceImpl(this._maybeClient);

  static const memberEventType = 'org.matrix.msc3401.call.member';
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
  var _isRestarting = false;
  var _session = 0;
  Timer? _restartTimer;
  Timer? _expiryTimer;
  Timer? _extendRetryTimer;
  Map<String, Object?>? _extension;
  Future<void>? _extending;

  Client get _client => _maybeClient ?? (throw const CallNoClientException());

  String get _userId => _client.userID ?? (throw const CallNoClientException());

  String get _deviceId =>
      _client.deviceID ?? (throw const CallNoClientException());

  Room _room(String roomId) {
    final room = _client.getRoomById(roomId);
    if (room == null || room.membership != Membership.join) {
      throw const CallRoomNotFoundException();
    }
    return room;
  }

  @visibleForTesting
  static String stateKeyFor({
    required String userId,
    required String deviceId,
    required String? roomVersion,
  }) {
    final stateKey = '${userId}_${deviceId}_m.call';
    final isUnprefixed =
        roomVersion != null && _unprefixedRoomVersion.hasMatch(roomVersion);
    return isUnprefixed ? stateKey : '_$stateKey';
  }

  @visibleForTesting
  static Map<String, Object?> membershipContent({
    required String userId,
    required String deviceId,
    required String serviceUrl,
    required bool isVideo,
    int expiries = 1,
    int? createdTs,
  }) => {
    'application': 'm.call',
    'call_id': '',
    'scope': 'm.room',
    'device_id': deviceId,
    'membershipID': '$userId:$deviceId',
    'expires': _membershipExpiry.inMilliseconds * expiries,
    'm.call.intent': isVideo ? 'video' : 'audio',
    'focus_active': {'type': 'livekit', 'focus_selection': 'oldest_membership'},
    'foci_preferred': [
      {'type': 'livekit', 'livekit_service_url': serviceUrl},
    ],
    'created_ts': ?createdTs,
  };

  @visibleForTesting
  static CallServer parseServer(int statusCode, String body) {
    if (statusCode ~/ 100 != 2) {
      throw CallTokenFailedException(cause: 'HTTP $statusCode');
    }
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic>) {
      throw const CallTokenFailedException(cause: 'Unexpected body');
    }
    final response = SfuTokenResponse.fromJson(json);
    final url = response.url;
    final jwt = response.jwt;
    if (url == null || jwt == null) {
      throw const CallTokenFailedException(cause: 'No url or jwt');
    }
    return CallServer(url: url, token: jwt);
  }

  String _ownStateKey(Room room) => stateKeyFor(
    userId: _userId,
    deviceId: _deviceId,
    roomVersion: room.roomVersion,
  );

  @override
  CallRoomInfo getRoomInfo(String roomId) {
    final room = _room(roomId);
    return CallRoomInfo(
      isEncrypted: room.encrypted,
      isDirect: room.isDirectChat,
    );
  }

  @override
  ({String? displayName, Uri? avatarUrl}) memberProfile({
    required String roomId,
    required String userId,
  }) {
    final user = _maybeClient
        ?.getRoomById(roomId)
        ?.unsafeGetUserFromMemoryOrFallback(userId);
    return (displayName: user?.calcDisplayname(), avatarUrl: user?.avatarUrl);
  }

  @override
  Future<CallServer> fetchServer({
    required String roomId,
    required String serviceUrl,
  }) async {
    final client = _client;
    _room(roomId);
    final userId = _userId;
    final deviceId = _deviceId;
    try {
      final openIdToken = await client.requestOpenIdToken(userId, {});
      final response = await client.httpClient
          .post(
            Uri.parse('$serviceUrl/sfu/get'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'room': roomId,
              'openid_token': openIdToken.toJson(),
              'device_id': deviceId,
            }),
          )
          .timeout(_tokenTimeout);
      return parseServer(response.statusCode, response.body);
    } on CallException {
      rethrow;
    } catch (error) {
      throw CallTokenFailedException(cause: error);
    }
  }

  @override
  Future<void> endStaleOwnMembership(String roomId) async {
    final room = _room(roomId);
    try {
      await room.postLoad();
    } catch (error) {
      throw CallMembershipFailedException(cause: error);
    }
    final stateKey = _ownStateKey(room);
    final deviceId = room
        .getState(memberEventType, stateKey)
        ?.content
        .tryGet<String>('device_id');
    if (deviceId == null) return;
    try {
      await _client.setRoomStateWithKey(roomId, memberEventType, stateKey, {});
    } catch (error, stackTrace) {
      Logs().w('MatrixRtcDatasource: stale membership kept', error, stackTrace);
    }
  }

  @override
  Future<void> joinMembership({
    required String roomId,
    required String serviceUrl,
    required bool isVideo,
  }) async {
    final room = _room(roomId);
    if (!room.canChangeStateEvent(memberEventType)) {
      throw const CallNoPermissionException();
    }
    final stateKey = _ownStateKey(room);
    Map<String, Object?> contentFor({int expiries = 1, int? createdTs}) =>
        membershipContent(
          userId: _userId,
          deviceId: _deviceId,
          serviceUrl: serviceUrl,
          isVideo: isVideo,
          expiries: expiries,
          createdTs: createdTs,
        );
    await _scheduleDelayedLeave(roomId, stateKey);
    try {
      await _client.setRoomStateWithKey(
        roomId,
        memberEventType,
        stateKey,
        contentFor(),
      );
    } catch (error) {
      _stopTimers();
      throw CallMembershipFailedException(cause: error);
    }
    _resendMembership = () => _client.setRoomStateWithKey(
      roomId,
      memberEventType,
      stateKey,
      contentFor(),
    );
    _extendBeforeExpiry(roomId, stateKey, contentFor);
  }

  /// `expires` grows by its own length before it lapses, from the same
  /// `created_ts`.
  void _extendBeforeExpiry(
    String roomId,
    String stateKey,
    Map<String, Object?> Function({int expiries, int? createdTs}) contentFor,
  ) {
    final createdTs = DateTime.now().millisecondsSinceEpoch;
    var expiries = 1;
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(_membershipExpiry - _expiryHeadroom, (_) {
      expiries++;
      _extension = contentFor(expiries: expiries, createdTs: createdTs);
      _queueExtension(roomId, stateKey);
    });
  }

  /// One write at a time, always the newest content: an older one never
  /// lands last.
  void _queueExtension(String roomId, String stateKey) {
    final session = _session;
    _extending = (_extending ?? Future<void>.value()).then(
      (_) => _extend(roomId, stateKey, session),
    );
  }

  Future<void> _extend(String roomId, String stateKey, int session) async {
    final content = _extension;
    if (content == null || session != _session) return;
    try {
      await _client.setRoomStateWithKey(
        roomId,
        memberEventType,
        stateKey,
        content,
      );
    } catch (error, stackTrace) {
      Logs().w('MatrixRtcDatasource: not extended', error, stackTrace);
      if (session != _session) return;
      _extendRetryTimer?.cancel();
      _extendRetryTimer = Timer(
        _extendRetry,
        () => _queueExtension(roomId, stateKey),
      );
    }
  }

  /// The homeserver ends the membership itself if this device vanishes
  /// (MSC4140); without delayed events the membership expires instead.
  Future<void> _scheduleDelayedLeave(String roomId, String stateKey) async {
    final session = _session;
    final String delayId;
    try {
      delayId = await _client.setRoomStateWithKeyWithDelay(
        roomId,
        memberEventType,
        stateKey,
        _delayedLeave.inMilliseconds,
        {},
      );
    } catch (error, stackTrace) {
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
    _restartTimer = Timer.periodic(
      _delayedLeaveRestart,
      (_) => unawaited(_restartDelayedLeave(roomId, stateKey)),
    );
  }

  Future<void> _restartDelayedLeave(String roomId, String stateKey) async {
    final delayId = _delayId;
    if (delayId == null || _isRestarting) return;
    _isRestarting = true;
    final session = _session;
    try {
      await _client.manageDelayedEvent(delayId, DelayedEventAction.restart);
    } on MatrixException catch (error) {
      // Left meanwhile: the leave consumed the delayed event.
      if (error.error != MatrixError.M_NOT_FOUND || _delayId != delayId) return;
      // Paused too long: the homeserver ended the membership.
      await _scheduleDelayedLeave(roomId, stateKey);
      if (session != _session) return;
      await _resendMembership?.call().catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        Logs().w('MatrixRtcDatasource: not sent again', error, stackTrace);
      });
    } catch (error, stackTrace) {
      Logs().w('MatrixRtcDatasource: restart failed', error, stackTrace);
    } finally {
      _isRestarting = false;
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
  Future<void> leaveMembership(String roomId) async {
    final delayId = _stopTimers();
    // An extension still in flight would otherwise land after the leave.
    final extending = _extending;
    _extending = null;
    await extending;
    if (delayId != null) {
      try {
        await _client.manageDelayedEvent(delayId, DelayedEventAction.send);
        return;
      } catch (error, stackTrace) {
        Logs().w('MatrixRtcDatasource: delayed leave', error, stackTrace);
      }
    }
    final room = _room(roomId);
    try {
      await _client.setRoomStateWithKey(
        roomId,
        memberEventType,
        _ownStateKey(room),
        {},
      );
    } catch (error) {
      throw CallMembershipFailedException(cause: error);
    }
  }

  void dispose() => _stopTimers();
}
