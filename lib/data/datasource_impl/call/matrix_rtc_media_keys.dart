import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/call/call_media_key.dart';

typedef CallMemberDevice = ({String userId, String deviceId, int createdTs});

typedef MediaKeyPlan = ({bool rotates, Set<CallMemberDevice> recipients});

typedef ReceivedMediaKey = ({
  String userId,
  String deviceId,
  String senderKey,
  int index,
  List<int> key,
});

typedef _Membership = ({CallMemberDevice device, int? expiresAt});

/// The media keys of an encrypted call (DECISION.md D14): each device sends
/// its own key to the others over Olm, a new one when someone leaves.
class MatrixRtcMediaKeys {
  MatrixRtcMediaKeys(
    this._client,
    this._roomId,
    this._memberEventType, {
    @visibleForTesting DateTime Function() now = DateTime.now,
  }) : _now = now;

  static const eventType = 'io.element.call.encryption_keys';
  // MSC4143's delay: a slow sync still gets the key before it encrypts.
  static const useKeyDelay = Duration(seconds: 5);
  static const retryDelay = Duration(seconds: 2);
  static const _maxRetries = 3;
  static const _rotationGracePeriod = Duration(seconds: 10);
  static const _keyringSize = 256;
  static const _maxPendingKeys = 64;
  static final _random = Random.secure();

  final Client _client;
  final String _roomId;
  final String _memberEventType;
  final DateTime Function() _now;

  final _keys = StreamController<CallMediaKey>();
  final _subscriptions = <StreamSubscription<Object?>>[];
  var _sharedWith = <CallMemberDevice>{};
  var _index = 0;
  var _key = <int>[];
  late var _createdAt = _now();
  var _rollout = Future<void>.value();
  Timer? _retry;
  var _retries = 0;
  var _rotationPending = false;
  Timer? _expiry;

  /// Keys of devices whose membership has not arrived yet.
  final _pendingKeys = <String, ReceivedMediaKey>{};

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

  /// The sending device is the Olm sender and its claimed device, never an
  /// id the content names.
  @visibleForTesting
  static ReceivedMediaKey? parseKey(ToDeviceEvent event, String roomId) {
    if (event.type != eventType || event.encryptedContent == null) return null;
    final content = event.content;
    if (content.tryGet<String>('room_id') != roomId) return null;
    final member = content.tryGetMap<String, Object?>('member');
    return switch ((
      _mediaKeyOf(content, 'media_key') ?? _mediaKeyOf(content, 'keys'),
      member?.tryGet<String>('claimed_device_id'),
      event.encryptedContent?.tryGet<String>('sender_key'),
    )) {
      (
        (:final index, :final key),
        final String deviceId,
        final String senderKey,
      )
          when index >= 0 && index < _keyringSize =>
        (
          userId: event.senderId,
          deviceId: deviceId,
          senderKey: senderKey,
          index: index,
          key: key,
        ),
      _ => null,
    };
  }

  // `keys` is deprecated in favour of `media_key`: both carry `{index, key}`.
  static ({int index, List<int> key})? _mediaKeyOf(
    Map<String, Object?> content,
    String field,
  ) {
    final mediaKey = content.tryGetMap<String, Object?>(field);
    return switch ((
      mediaKey?.tryGet<int>('index'),
      _decodeKey(mediaKey?.tryGet<String>('key')),
    )) {
      (final int index, final List<int> key) => (index: index, key: key),
      _ => null,
    };
  }

  static List<int>? _decodeKey(String? key) {
    if (key == null) return null;
    try {
      final bytes = base64.decode(base64.normalize(key));
      return bytes.isEmpty ? null : bytes;
    } on FormatException {
      return null;
    }
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
      ..add(_client.onToDeviceEvent.stream.listen(_onToDeviceEvent))
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

  void _onToDeviceEvent(ToDeviceEvent event) {
    final key = parseKey(event, _roomId);
    if (key == null || _isOwnDevice(key.userId, key.deviceId)) return;
    _pendingKeys.remove(_pendingId(key));
    _pendingKeys[_pendingId(key)] = key;
    if (_pendingKeys.length > _maxPendingKeys) {
      _pendingKeys.remove(_pendingKeys.keys.first);
    }
    _deliverKeys(_members());
  }

  static String _pendingId(ReceivedMediaKey key) =>
      '${key.userId}|${key.deviceId}|${key.index}';

  /// Only a device of the call may set a key, and only its own: the Olm
  /// session it came over must be that device's.
  void _deliverKeys(Set<CallMemberDevice> members) {
    final memberIds = {
      for (final member in members) '${member.userId}|${member.deviceId}',
    };
    _pendingKeys.removeWhere((_, key) {
      if (!memberIds.contains('${key.userId}|${key.deviceId}')) return false;
      final deviceKeys =
          _client.userDeviceKeys[key.userId]?.deviceKeys[key.deviceId];
      if (deviceKeys == null) return false;
      if (deviceKeys.curve25519Key != key.senderKey) return true;
      _keys.add(
        CallMediaKey(
          participantId: '${key.userId}:${key.deviceId}',
          index: key.index,
          key: key.key,
        ),
      );
      return true;
    });
  }

  bool _isOwnDevice(String userId, String deviceId) =>
      userId == _client.userID && deviceId == _client.deviceID;

  Future<void> _stop() async {
    _retry?.cancel();
    _retry = null;
    _expiry?.cancel();
    _expiry = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  void _queueRollout() => _rollout = _rollout.then((_) => _rolloutKey());

  Future<void> _rolloutKey() async {
    if (_subscriptions.isEmpty) return;
    final members = _refreshMembers();
    // The others take a key from this device once they see its membership.
    if (members == null) return;
    final (:rotates, :recipients) = _nextShare(members);
    if (recipients.isEmpty) {
      _shareWithNobody(members, rotates: rotates);
      return;
    }
    final sent = await _sendOrRetry(recipients);
    if (sent == null) return;
    _recordShare(members, recipients, sent, rotates: rotates);
    if (!rotates) return;
    // The others get the key before it encrypts anything.
    await Future<void>.delayed(useKeyDelay);
    _useOwnKey();
  }

  /// The other devices of the call, or null while this device's own
  /// membership is not visible yet.
  Set<CallMemberDevice>? _refreshMembers() {
    final memberships = _memberships();
    final members = _othersOf(memberships);
    _deliverKeys(members);
    _watchExpiry(memberships);
    return members.length == memberships.length ? null : members;
  }

  MediaKeyPlan _nextShare(Set<CallMemberDevice> members) {
    final plan = MatrixRtcMediaKeys.plan(
      sharedWith: _sharedWith,
      members: members,
      keyAge: _now().difference(_createdAt),
    );
    // A failed rotation is not retried as a mere join.
    final rotates = plan.rotates || _rotationPending;
    // A leaver gets no later key, even when nobody is left to send it to.
    if (rotates) {
      _index = (_index + 1) % _keyringSize;
      _key = _newKey();
      _rotationPending = true;
    }
    return (rotates: rotates, recipients: rotates ? members : plan.recipients);
  }

  void _shareWithNobody(
    Set<CallMemberDevice> members, {
    required bool rotates,
  }) {
    _sharedWith = members;
    _rotationPending = false;
    if (rotates) _useOwnKey();
  }

  Future<Set<CallMemberDevice>?> _sendOrRetry(
    Set<CallMemberDevice> recipients,
  ) async {
    try {
      return await _send(recipients);
    } catch (error, stackTrace) {
      Logs().w('MatrixRtcMediaKeys: key not sent', error, stackTrace);
      _retryLater();
      return null;
    }
  }

  void _recordShare(
    Set<CallMemberDevice> members,
    Set<CallMemberDevice> recipients,
    Set<CallMemberDevice> sent, {
    required bool rotates,
  }) {
    _sharedWith = rotates ? sent : {..._sharedWith, ...sent};
    // The refresh may have brought the device keys a held key waited for.
    _deliverKeys(members);
    if (sent.length < recipients.length) {
      _retryLater();
      return;
    }
    _retries = 0;
    _rotationPending = false;
  }

  void _useOwnKey() {
    if (_subscriptions.isEmpty) return;
    _keys.add(CallMediaKey(participantId: _ownId, index: _index, key: _key));
  }

  void _retryLater() {
    if (_retries >= _maxRetries || _subscriptions.isEmpty) return;
    _retries++;
    _retry?.cancel();
    _retry = Timer(retryDelay * _retries, _queueRollout);
  }

  List<int> _newKey() {
    _createdAt = _now();
    return List<int>.generate(16, (_) => _random.nextInt(256));
  }

  Set<CallMemberDevice> _members() => _othersOf(_memberships());

  Set<CallMemberDevice> _othersOf(List<_Membership> memberships) => {
    for (final membership in memberships)
      if (!_isOwnDevice(membership.device.userId, membership.device.deviceId))
        membership.device,
  };

  /// The live memberships of the call, this device's included.
  List<_Membership> _memberships() {
    final room = _client.getRoomById(_roomId);
    final events = room?.states[_memberEventType]?.values ?? const [];
    final now = _now().millisecondsSinceEpoch;
    return [
      for (final event in events)
        if (_membershipOf(event, now) case final membership?) membership,
    ];
  }

  _Membership? _membershipOf(StrippedStateEvent event, int now) {
    final content = event.content;
    final deviceId = content.tryGet<String>('device_id');
    if (deviceId == null) return null;
    if ((content.tryGet<String>('application') ?? 'm.call') != 'm.call') {
      return null;
    }
    if ((content.tryGet<String>('call_id') ?? '') != '') return null;
    final createdTs =
        content.tryGet<int>('created_ts') ??
        (event is Event ? event.originServerTs.millisecondsSinceEpoch : now);
    final expires = content.tryGet<int>('expires') ?? 0;
    final expiresAt = expires > 0 ? createdTs + expires : null;
    if (expiresAt != null && expiresAt <= now) return null;
    return (
      device: (
        userId: event.senderId,
        deviceId: deviceId,
        createdTs: createdTs,
      ),
      expiresAt: expiresAt,
    );
  }

  /// A device that vanished without a delayed leave only expires: the key
  /// changes then too.
  void _watchExpiry(List<_Membership> memberships) {
    _expiry?.cancel();
    final expiries = [
      for (final membership in memberships)
        if (membership.expiresAt case final expiresAt?) expiresAt,
    ];
    if (expiries.isEmpty) return;
    final next = DateTime.fromMillisecondsSinceEpoch(expiries.reduce(min));
    _expiry = Timer(next.difference(_now()), _queueRollout);
  }

  /// The devices the key went to: a device whose keys are unknown even after
  /// a refresh is left for a retry.
  Future<Set<CallMemberDevice>> _send(Set<CallMemberDevice> recipients) async {
    final missingUsers = {
      for (final member in recipients)
        if (_deviceKeysOf(member) == null) member.userId,
    };
    if (missingUsers.isNotEmpty) {
      await _client.updateUserDeviceKeys(additionalUsers: missingUsers);
    }
    final devices = {
      for (final member in recipients)
        if (_deviceKeysOf(member) case final deviceKeys?) member: deviceKeys,
    };
    if (devices.isEmpty) return const {};
    final mediaKey = {'index': _index, 'key': base64.encode(_key)};
    await _client.sendToDeviceEncrypted(devices.values.toList(), eventType, {
      'media_key': mediaKey,
      'keys': mediaKey,
      'room_id': _roomId,
      'member_id': _ownId,
      'member': {'claimed_device_id': _client.deviceID, 'id': _ownId},
      'session': {'call_id': '', 'application': 'm.call', 'scope': 'm.room'},
      'sent_ts': _now().millisecondsSinceEpoch,
    });
    return devices.keys.toSet();
  }

  DeviceKeys? _deviceKeysOf(CallMemberDevice member) =>
      _client.userDeviceKeys[member.userId]?.deviceKeys[member.deviceId];
}
