import 'dart:async';

/// Runs the tasks of a room one after the other, in the order they were
/// queued. Rooms do not wait for each other.
final class RoomSendQueueService {
  final Map<String, Future<void>> _lastByRoomId = {};

  /// Completes with the result of [task], once every task queued before it
  /// for [roomId] is done. A failed task does not block the next ones.
  Future<T> enqueue<T>(String roomId, Future<T> Function() task) async {
    final Future<void>? previous = _lastByRoomId[roomId];
    final Completer<void> done = Completer<void>();
    final Future<void> last = done.future;
    _lastByRoomId[roomId] = last;
    try {
      await previous;
      return await task();
    } finally {
      done.complete();
      if (_lastByRoomId[roomId] == last) _lastByRoomId.remove(roomId);
    }
  }
}
