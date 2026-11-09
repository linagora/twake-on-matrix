/// Sends the read receipt of a thread screen once per reply: the screen
/// reads its last reply on every scroll, and a receipt still on its way (or
/// already taken) must not be sent again. A failed one is sent again on the
/// next read.
class ThreadReadMarker {
  ThreadReadMarker(this._send);

  final Future<void> Function(String eventId) _send;
  String? _onItsWay;
  String? _taken;

  Future<void> read(String eventId) async {
    if (eventId == _onItsWay || eventId == _taken) return;
    _onItsWay = eventId;
    try {
      await _send(eventId);
      _taken = eventId;
    } finally {
      if (_onItsWay == eventId) _onItsWay = null;
    }
  }
}
