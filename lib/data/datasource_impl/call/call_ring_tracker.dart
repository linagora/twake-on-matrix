import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/matrix_events/call_event_types.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_ring.dart';

/// The rings (MSC4075) of the timeline that still ring for the account:
/// someone else's, neither lapsed, declined (MSC4310) nor answered.
class CallRingTracker {
  CallRingTracker(Client client) : _client = client {
    _subscription = client.onTimelineEvent.stream.listen(_onEvent);
    _syncSubscription = client.onSync.stream.listen((_) => _onSync());
  }

  static const defaultLifetime = Duration(seconds: 60);
  static const maxLifetime = Duration(seconds: 120);

  final Client _client;
  late final StreamSubscription<Event> _subscription;
  late final StreamSubscription<SyncUpdate> _syncSubscription;
  final _rings = <String, CallRing>{};
  final _timers = <String, Timer>{};
  final _pending = <String, MissedCall>{};
  final _seenLive = <String>{};
  final _memberships = <String, String>{};
  final _changes = StreamController<List<CallRing>>.broadcast();
  final _missed = StreamController<MissedCall>.broadcast();

  Stream<List<CallRing>> get rings => _changes.stream;

  Stream<MissedCall> get missedCalls => _missed.stream;

  /// Stops the ring of this device at once, without waiting for its decline
  /// to come back.
  void dismiss(String ringId) {
    if (_rings.containsKey(ringId)) {
      _remove(ringId);
    }
  }

  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    // A check awaiting a room load must find nothing left to settle.
    _rings.clear();
    _subscription.cancel().ignore();
    _syncSubscription.cancel().ignore();
    _changes.close().ignore();
    _missed.close().ignore();
  }

  void _onEvent(Event event) {
    switch (event.type) {
      case CallEventTypes.callMember:
        _onMembership(event);
      case EventTypes.RoomMember:
        _onRoomMember(event);
      case CallEventTypes.callDecline || CallEventTypes.callDeclineStable:
        _onDecline(event);
      case 'org.matrix.msc4075.rtc.notification' || CallEventTypes.callNotify:
        _onRing(event);
    }
  }

  void _onMembership(Event event) {
    final inCall = event.content['device_id'] is String;
    if (!inCall || event.senderId != _client.userID) return;
    _removeRoom(event.roomId);
  }

  /// Left or removed: the rings of that room are for the account no more.
  void _onRoomMember(Event event) {
    if (event.stateKey != _client.userID) return;
    if (event.content['membership'] == Membership.join.name) return;
    _removeRoom(event.roomId);
  }

  void _removeRoom(String? roomId) => [
    for (final ring in _rings.values)
      if (ring.room.id == roomId) ring.eventId,
  ].forEach(_remove);

  /// A join can come with a limited sync only as room state. A call that had
  /// a member and has none left rings no more: the caller hung up, a missed
  /// call. Before a member was seen the ring runs to its end: the membership
  /// may not have come yet, or not as a state event. Unless the membership
  /// the ring relates to was replaced: the caller left before this device
  /// saw them.
  void _onSync() => _rings.keys.toList().forEach(_checkCall);

  Future<void> _checkCall(String ringId) async {
    final room = _client.getRoomById(_rings[ringId]?.room.id ?? '');
    if (room == null) return;
    if (room.membership != Membership.join) return _remove(ringId);
    if (!await _isLoaded(room)) return;
    if (!_rings.containsKey(ringId)) return;
    final live = _liveMembers(room);
    if (live.any((member) => member.senderId == _client.userID)) {
      _remove(ringId);
    } else if (live.isNotEmpty) {
      _seenLive.add(ringId);
    } else if (_seenLive.contains(ringId) || _callerLeft(room, ringId)) {
      _lapse(ringId);
    }
  }

  /// With no live member, any membership of the caller is a leave.
  bool _callerLeft(Room room, String ringId) {
    final membership = _memberships[ringId];
    if (membership == null) return false;
    final caller = _rings[ringId]?.senderId;
    return room.states[CallEventTypes.callMember]?.values.any(
          (member) =>
              member.senderId == caller &&
              member is Event &&
              member.eventId != membership,
        ) ??
        false;
  }

  /// A partial room keeps no call member in its states: no member is not
  /// known to be none until it is loaded.
  static Future<bool> _isLoaded(Room room) async {
    try {
      await room.postLoad();
      return true;
    } on Exception catch (error, stackTrace) {
      Logs().w('CallRingTracker: room not loaded', error, stackTrace);
      return false;
    }
  }

  static List<StrippedStateEvent> _liveMembers(Room room) => [
    ...?room.states[CallEventTypes.callMember]?.values.where(isLiveMembership),
  ];

  void _onDecline(Event event) {
    if (event.senderId != _client.userID) return;
    if (ringIdOf(event) case final ringId?) dismiss(ringId);
  }

  static bool isDecline(Event event) =>
      event.type == CallEventTypes.callDecline ||
      event.type == CallEventTypes.callDeclineStable;

  /// The ring a decline relates to.
  static String? ringIdOf(Event event) {
    final relates = event.content['m.relates_to'];
    final ringId = relates is Map ? relates['event_id'] : null;
    return ringId is String ? ringId : null;
  }

  void _onRing(Event event) {
    if (!_isForUs(event)) return;
    final room = event.room;
    final caller = event.senderFromMemoryOrFallback;
    final ring = CallRing(
      eventId: event.eventId,
      room: CallRoom(event.roomId!),
      senderId: event.senderId,
      isVideo: event.content['m.call.intent'] == 'video',
      expiresAt: event.originServerTs.add(_lifetimeOf(event)),
      callerName: caller.calcDisplayname(),
      roomName: room.getLocalizedDisplayname(),
      // A direct chat shows the other person, a group shows who calls.
      avatarUrl: room.isDirectChat ? room.avatar : caller.avatarUrl,
      isDirect: room.isDirectChat,
    );
    final left = ring.expiresAt.difference(DateTime.now());
    if (left <= Duration.zero) return;
    _rings[ring.eventId] = ring;
    if (event.content['m.relates_to'] case {
      'event_id': final String membership,
    }) {
      _memberships[ring.eventId] = membership;
    }
    _pending[ring.eventId] = MissedCall(
      ringEventId: ring.eventId,
      room: ring.room,
      callerId: ring.senderId,
      sentAt: event.originServerTs,
      isVideo: ring.isVideo,
    );
    _timers[ring.eventId] = Timer(left, () => _lapse(ring.eventId));
    _emit();
  }

  /// A ring of someone else, not yet answered here, that mentions the
  /// account.
  bool _isForUs(Event event) {
    final userId = _client.userID;
    if (userId == null || _isOwnOrKnown(event)) return false;
    if (!_isRing(event) || _isInCallHere(event.room)) return false;
    return !_mentionsOnlyOthers(event, userId);
  }

  /// A ring rings the whole room unless it names other people only.
  static bool _mentionsOnlyOthers(Event event, String userId) {
    final mentions = event.content['m.mentions'];
    if (mentions is! Map || mentions['room'] == true) return false;
    final userIds = mentions['user_ids'];
    return userIds is List && userIds.isNotEmpty && !userIds.contains(userId);
  }

  bool _isOwnOrKnown(Event event) =>
      event.senderId == _client.userID || _rings.containsKey(event.eventId);

  static bool _isRing(Event event) {
    final key = event.type == CallEventTypes.callNotify
        ? 'notify_type'
        : 'notification_type';
    return event.content[key] == 'ring';
  }

  /// From the server time of the event, not from `sender_ts`: the clock of the
  /// sender cannot make a ring last.
  static Duration _lifetimeOf(Event event) {
    final lifetime = event.content['lifetime'];
    if (lifetime is! int) return defaultLifetime;
    final bounded = Duration(milliseconds: lifetime);
    return bounded > maxLifetime ? maxLifetime : bounded;
  }

  bool _isInCallHere(Room room) =>
      room.states[CallEventTypes.callMember]?.values.any(
        (member) =>
            member.senderId == _client.userID &&
            member.content['device_id'] == _client.deviceID &&
            isLiveMembership(member),
      ) ??
      false;

  /// A membership of someone in the call, not left nor expired. Without
  /// `created_ts` it expires from the server time of its event.
  static bool isLiveMembership(StrippedStateEvent member) {
    final content = member.content;
    if (content['device_id'] is! String) return false;
    final expires = content['expires'];
    final createdTs =
        content['created_ts'] ??
        (member is Event ? member.originServerTs.millisecondsSinceEpoch : null);
    return expires is! int ||
        createdTs is! int ||
        createdTs + expires >= DateTime.now().millisecondsSinceEpoch;
  }

  void _lapse(String ringId) {
    final missed = _pending[ringId];
    _remove(ringId);
    if (missed != null) _missed.add(missed);
  }

  void _remove(String ringId) {
    _rings.remove(ringId);
    _pending.remove(ringId);
    _seenLive.remove(ringId);
    _memberships.remove(ringId);
    _timers.remove(ringId)?.cancel();
    _emit();
  }

  void _emit() => _changes.add(List.unmodifiable(_rings.values));
}
