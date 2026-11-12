import 'dart:async';

import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/data/model/call/call_member_content.dart';

/// `expires` of a membership grows by its own length before it lapses, from
/// the same `created_ts`. One per joined call.
class CallMembershipExtender {
  CallMembershipExtender(this._write);

  static const _headroom = Duration(minutes: 1);
  static const _retry = Duration(seconds: 30);

  final Future<void> Function(Map<String, Object?> content) _write;
  Timer? _expiryTimer;
  Timer? _retryTimer;
  Map<String, Object?>? _extension;
  Future<void>? _extending;
  var _isStopped = false;

  void start(
    Map<String, Object?> Function(MembershipExpiry expiry) contentFor,
  ) {
    final createdTs = DateTime.now().millisecondsSinceEpoch;
    var count = 1;
    _expiryTimer = Timer.periodic(CallMemberContent.lifetime - _headroom, (_) {
      count++;
      _extension = contentFor((count: count, createdTs: createdTs));
      _queue();
    });
  }

  /// Completes once a write still in flight has landed.
  Future<void> stop() {
    _isStopped = true;
    _expiryTimer?.cancel();
    _retryTimer?.cancel();
    _extension = null;
    return _extending ?? Future<void>.value();
  }

  /// One write at a time, always the newest content: an older one never
  /// lands last.
  void _queue() {
    _extending = (_extending ?? Future<void>.value()).then((_) => _extend());
  }

  Future<void> _extend() async {
    final content = _extension;
    if (content == null || _isStopped) return;
    try {
      await _write(content);
    } on Exception catch (error, stackTrace) {
      Logs().w('MatrixRtcDatasource: not extended', error, stackTrace);
      if (_isStopped) return;
      _retryTimer?.cancel();
      _retryTimer = Timer(_retry, _queue);
    }
  }
}
