import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/call/call_media_key.dart';

typedef CallMemberDevice = ({String userId, String deviceId, int createdTs});

typedef MediaKeyPlan = ({bool rotates, Set<CallMemberDevice> recipients});

/// The media keys of an encrypted call (DECISION.md D14): each device sends
/// its own key to the others over Olm, a new one when someone leaves.
class MatrixRtcMediaKeys {
  MatrixRtcMediaKeys(this._client, this._roomId, this._memberEventType);

  static const eventType = 'io.element.call.encryption_keys';
  static const _useKeyDelay = Duration(seconds: 1);
  static const _rotationGracePeriod = Duration(seconds: 10);
  static const _keyringSize = 256;
  static final _random = Random.secure();

  final Client _client;
  final String _roomId;
  final String _memberEventType;

  final _keys = StreamController<CallMediaKey>();
  final _subscriptions = <StreamSubscription<Object?>>[];
  var _sharedWith = <CallMemberDevice>{};
  var _index = 0;
  var _key = <int>[];
  var _createdAt = DateTime.now();
  var _rollout = Future<void>.value();

  String get _ownId => '${_client.userID}:${_client.deviceID}';

  /// Starts on listen, stops when the subscription is cancelled.
  Stream<CallMediaKey> run() {
    _keys.onListen = _start;
    _keys.onCancel = _stop;
    return _keys.stream;
  }

  /// A member who left gets no later key: the key changes. A joiner gets the
  /// current key while it is recent, else everyone gets a new one.
  @visibleForTesting
  static MediaKeyPlan plan({
    required Set<CallMemberDevice> sharedWith,
    required Set<CallMemberDevice> members,
    required Duration keyAge,
  }) {
    final hasLeaver = sharedWith.difference(members).isNotEmpty;
    final joiners = members.difference(sharedWith);
    final staleForJoiners =
        joiners.isNotEmpty && keyAge >= _rotationGracePeriod;
    if (hasLeaver || staleForJoiners) {
      return (rotates: true, recipients: members);
    }
    return (rotates: false, recipients: joiners);
  }

  @visibleForTesting
  static CallMediaKey? parseKey(ToDeviceEvent event, String roomId) {
    if (event.type != eventType || event.encryptedContent == null) return null;
    final content = event.content;
    if (content.tryGet<String>('room_id') != roomId) return null;
    final keys = content.tryGetMap<String, Object?>('keys');
    final member = content.tryGetMap<String, Object?>('member');
    return switch ((
      keys?.tryGet<int>('index'),
      keys?.tryGet<String>('key'),
      member?.tryGet<String>('claimed_device_id'),
    )) {
      (final int index, final String key, final String deviceId) =>
        CallMediaKey(
          participantId:
              member?.tryGet<String>('id') ?? '${event.senderId}:$deviceId',
          index: index,
          key: base64.decode(base64.normalize(key)),
        ),
      _ => null,
    };
  }

  void _start() {
    _key = _newKey();
    _keys.add(CallMediaKey(participantId: _ownId, index: _index, key: _key));
    // A partially loaded room keeps no call memberships in its states.
    _rollout = (_client.getRoomById(_roomId)?.postLoad() ?? Future.value())
        .catchError((Object error, StackTrace stackTrace) {
          Logs().w('MatrixRtcMediaKeys: room not loaded', error, stackTrace);
        });
    _subscriptions
      ..add(
        _client.onToDeviceEvent.stream.listen((event) {
          final key = parseKey(event, _roomId);
          if (key != null) _keys.add(key);
        }),
      )
      ..add(
        _client.onRoomState.stream
            .where(
              (update) =>
                  update.roomId == _roomId &&
                  update.state.type == _memberEventType,
            )
            .listen((_) => _queueRollout()),
      );
    _queueRollout();
  }

  Future<void> _stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  void _queueRollout() => _rollout = _rollout.then((_) => _rolloutKey());

  Future<void> _rolloutKey() async {
    final members = _members();
    final plan = MatrixRtcMediaKeys.plan(
      sharedWith: _sharedWith,
      members: members,
      keyAge: DateTime.now().difference(_createdAt),
    );
    if (plan.recipients.isEmpty) {
      _sharedWith = members;
      return;
    }
    if (plan.rotates) {
      _index = (_index + 1) % _keyringSize;
      _key = _newKey();
    }
    try {
      await _send(plan.recipients);
    } catch (error, stackTrace) {
      Logs().w('MatrixRtcMediaKeys: key not sent', error, stackTrace);
      return;
    }
    _sharedWith = plan.rotates ? members : {..._sharedWith, ...plan.recipients};
    if (!plan.rotates || _keys.isClosed) return;
    // The others get the key before it encrypts anything.
    await Future<void>.delayed(_useKeyDelay);
    if (_subscriptions.isEmpty) return;
    _keys.add(CallMediaKey(participantId: _ownId, index: _index, key: _key));
  }

  List<int> _newKey() {
    _createdAt = DateTime.now();
    return List<int>.generate(16, (_) => _random.nextInt(256));
  }

  Set<CallMemberDevice> _members() {
    final room = _client.getRoomById(_roomId);
    final events = room?.states[_memberEventType]?.values ?? const [];
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      for (final event in events)
        if (_memberOf(event, now) case final member?) member,
    };
  }

  CallMemberDevice? _memberOf(StrippedStateEvent event, int now) {
    final content = event.content;
    final deviceId = content.tryGet<String>('device_id');
    if (deviceId == null) return null;
    if (event.senderId == _client.userID && deviceId == _client.deviceID) {
      return null;
    }
    if ((content.tryGet<String>('application') ?? 'm.call') != 'm.call') {
      return null;
    }
    if ((content.tryGet<String>('call_id') ?? '') != '') return null;
    final createdTs =
        content.tryGet<int>('created_ts') ??
        (event is Event ? event.originServerTs.millisecondsSinceEpoch : now);
    final expires = content.tryGet<int>('expires') ?? 0;
    if (expires > 0 && createdTs + expires <= now) return null;
    return (userId: event.senderId, deviceId: deviceId, createdTs: createdTs);
  }

  Future<void> _send(Set<CallMemberDevice> recipients) async {
    final userIds = {for (final member in recipients) member.userId};
    if (userIds.any((userId) => !_client.userDeviceKeys.containsKey(userId))) {
      await _client.updateUserDeviceKeys(additionalUsers: userIds);
    }
    final devices = [
      for (final member in recipients)
        ?_client.userDeviceKeys[member.userId]?.deviceKeys[member.deviceId],
    ];
    if (devices.isEmpty) return;
    await _client.sendToDeviceEncrypted(devices, eventType, {
      'keys': {'index': _index, 'key': base64.encode(_key)},
      'room_id': _roomId,
      'member': {'claimed_device_id': _client.deviceID, 'id': _ownId},
      'session': {'call_id': '', 'application': 'm.call', 'scope': 'm.room'},
      'sent_ts': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
