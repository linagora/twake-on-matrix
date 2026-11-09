/// A thread of a room: the room and the event that opened the thread.
class ThreadRef {
  const ThreadRef(this.roomId, this.rootEventId);

  final String roomId;
  final String rootEventId;

  /// Key under which the stores keep one thread.
  String get key => '$roomId|$rootEventId';
}
