import 'package:matrix/matrix.dart';

/// Where a message sent from the thread screen goes: the thread root, and the
/// last event of the thread (the reply fallback of the relation).
class ThreadSendTarget {
  const ThreadSendTarget({
    required this.rootEventId,
    required this.lastEventId,
  });

  final String rootEventId;
  final String lastEventId;

  /// The `m.relates_to` the SDK writes for a threaded message.
  Map<String, Object?> get relatesTo => {
    'rel_type': RelationshipTypes.thread,
    'event_id': rootEventId,
    'is_falling_back': true,
    'm.in_reply_to': {'event_id': lastEventId},
  };
}

extension ThreadSendTargetQuote on ThreadSendTarget? {
  /// A message sent to a thread never quotes.
  Event? withoutQuote(Event? inReplyTo) => this == null ? inReplyTo : null;
}
