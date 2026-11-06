/// Where a message sent from the thread screen goes: the thread root, and the
/// last event of the thread (the reply fallback of the relation).
class ThreadSendTarget {
  const ThreadSendTarget({
    required this.rootEventId,
    required this.lastEventId,
  });

  final String rootEventId;
  final String lastEventId;
}
