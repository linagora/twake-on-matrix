/// One call this device rang; its ring result touches this call only.
final class OutgoingCall {
  OutgoingCall._(this._isVideo, this._startedAt);

  final bool _isVideo;
  final DateTime _startedAt;
  String? _ringId;
  DateTime? _answeredAt;
  DateTime? _endedAt;

  bool get _isOpen => _endedAt == null;

  Map<String, Object?> _content(String ringId, DateTime endedAt) => {
    'intent': _isVideo ? 'video' : 'audio',
    'started_ts': _startedAt.millisecondsSinceEpoch,
    'answered_ts': ?_answeredAt?.millisecondsSinceEpoch,
    'ended_ts': endedAt.millisecondsSinceEpoch,
    'm.relates_to': {'rel_type': 'm.reference', 'event_id': ringId},
  };
}

/// The calls this device rang, one live per room: what the
/// `app.twake.chat.call` event written at their end says, as Twake Space
/// Chat writes it.
class OutgoingCalls {
  final _calls = <String, OutgoingCall>{};

  /// Calls hung up while their ring was still being sent.
  final _endedWhileRinging = <OutgoingCall>{};

  /// Before the ring is sent, so that a hang-up during the send is kept.
  OutgoingCall start(
    String roomId, {
    required bool isVideo,
    required DateTime startedAt,
  }) => _calls[roomId] = OutgoingCall._(isVideo, startedAt);

  /// The content of the call event when [call] already ended.
  Map<String, Object?>? rang(OutgoingCall call, String ringId) {
    call._ringId = ringId;
    if (!_endedWhileRinging.remove(call)) return null;
    return call._content(ringId, call._endedAt!);
  }

  /// The ring of [call] was not sent: it has no line.
  void dropRing(String roomId, OutgoingCall call) {
    _endedWhileRinging.remove(call);
    if (_calls[roomId] == call) _calls.remove(roomId);
  }

  bool isRinging(String roomId) => _calls.containsKey(roomId);

  Iterable<String> get roomIds => _calls.keys;

  /// The ring of the call still going in the room.
  String? ringIdOf(String roomId) {
    final call = _calls[roomId];
    return call != null && call._isOpen ? call._ringId : null;
  }

  /// The first other user in the call answers it.
  void answer(String roomId, DateTime at) {
    final call = _calls[roomId];
    if (call == null || !call._isOpen) return;
    call._answeredAt ??= at;
  }

  /// At hang-up: no answer counts after [at], however long leaving takes.
  void close(String roomId, DateTime at) {
    final call = _calls[roomId];
    if (call == null || !call._isOpen) return;
    call._endedAt = at;
  }

  void forget(String roomId) => _calls.remove(roomId);

  /// The content of the call event, null when no call of the room rang here,
  /// it already ended, or its ring is still being sent.
  Map<String, Object?>? end(String roomId) {
    final call = _calls.remove(roomId);
    if (call == null) return null;
    final endedAt = call._endedAt ??= DateTime.now();
    final ringId = call._ringId;
    if (ringId != null) return call._content(ringId, endedAt);
    _endedWhileRinging.add(call);
    return null;
  }
}
