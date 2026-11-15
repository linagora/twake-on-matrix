import 'dart:async';

/// Lets the pending files of a room join the upload queue in the order their
/// bubbles were shown, whatever order their bytes arrive in.
class PendingUploadOrder {
  /// The turn of the last file of each room, by room id.
  final Map<String, Future<void>> _last = {};

  /// Waits for [ready], then for every file of [roomId] given before, and
  /// calls [join] with what [ready] gave. A file that fails rethrows its
  /// error; the next file still waits for the ones before it.
  Future<R> inTurn<T, R>(
    String roomId,
    Future<T> ready,
    R Function(T value) join,
  ) async {
    final before = _last[roomId];
    final turn = Completer<void>();
    _last[roomId] = turn.future;
    try {
      final value = await ready;
      await before;
      // Synchronous, before the next file is let through.
      return join(value);
    } finally {
      // A failed file ends its turn only when the ones before it end theirs.
      turn.complete(before);
      unawaited(
        turn.future.then((_) {
          if (_last[roomId] == turn.future) _last.remove(roomId);
        }),
      );
    }
  }
}
