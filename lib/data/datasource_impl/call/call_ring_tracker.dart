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
  }

  static const defaultLifetime = Duration(seconds: 60);
  static const maxLifetime = Duration(seconds: 120);

  final Client _client;
  late final StreamSubscription<Event> _subscription;
  final _rings = <String, CallRing>{};
  final _timers = <String, Timer>{};
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
    _subscription.cancel().ignore();
    _changes.close().ignore();
    _missed.close().ignore();
  }

  void _onEvent(Event event) {
    switch (event.type) {
      case CallEventTypes.callMember:
        _onMembership(event);
      case CallEventTypes.callDecline || CallEventTypes.callDeclineStable:
        _onDecline(event);
      case 'org.matrix.msc4075.rtc.notification' || CallEventTypes.callNotify:
        _onRing(event);
    }
  }

  void _onMembership(Event event) {
    final inCall = event.content['device_id'] is String;
    if (!inCall || event.senderId != _client.userID) return;
    final inRoom = [
      for (final ring in _rings.values)
        if (ring.room.id == event.roomId) ring.eventId,
    ];
    inRoom.forEach(_remove);
  }

  void _onDecline(Event event) {
    if (event.senderId != _client.userID) return;
    final relates = event.content['m.relates_to'];
    final ringId = relates is Map ? relates['event_id'] : null;
    if (ringId is String) dismiss(ringId);
  }

  void _onRing(Event event) {
    if (!_isForUs(event)) return;
    final ring = CallRing(
      eventId: event.eventId,
      room: CallRoom(event.roomId!),
      senderId: event.senderId,
      isVideo: event.content['m.call.intent'] == 'video',
      expiresAt: event.originServerTs.add(_lifetimeOf(event)),
    );
    final left = ring.expiresAt.difference(DateTime.now());
    if (left <= Duration.zero) return;
    _rings[ring.eventId] = ring;
    _timers[ring.eventId] = Timer(left, () => _lapse(ring, event));
    _emit();
  }

  bool _isForUs(Event event) =>
      event.senderId != _client.userID &&
      !_rings.containsKey(event.eventId) &&
      _isRing(event) &&
      !_isInCallHere(event.room);

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
            member.content['device_id'] == _client.deviceID,
      ) ??
      false;

  void _lapse(CallRing ring, Event event) {
    _remove(ring.eventId);
    _missed.add(
      MissedCall(
        ringEventId: ring.eventId,
        room: ring.room,
        callerId: ring.senderId,
        sentAt: event.originServerTs,
        isVideo: ring.isVideo,
      ),
    );
  }

  void _remove(String ringId) {
    _rings.remove(ringId);
    _timers.remove(ringId)?.cancel();
    _emit();
  }

  void _emit() => _changes.add(List.unmodifiable(_rings.values));
}
