import 'package:collection/collection.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/thread/thread_relation_extension.dart';

/// What the card under a thread root shows: built from the server
/// aggregation of the root, then kept up to date with the replies, edits
/// and redactions received live.
class ThreadSummary {
  const ThreadSummary._({
    required this.rootEventId,
    required this.replyCount,
    required this.lastReply,
    required this.lastReplyText,
  });

  final String rootEventId;
  final int replyCount;

  /// Null when every reply known is deleted: the card shows the count only.
  final Event? lastReply;

  /// Text of [lastReply] with its latest edit applied.
  final String? lastReplyText;

  static ThreadSummary? fromRoot(
    Event root, {
    Iterable<Event> liveEvents = const [],
  }) {
    final aggregate = _aggregateOf(root);
    final serverLatest = _serverLatest(aggregate, root);

    // A redacted event loses its `m.relates_to`: match it by id.
    final deletedIds = _redactedIds(liveEvents);
    final replies = _liveReplies(root, liveEvents);
    final fresh = replies.where((e) => _isFresh(e, serverLatest));

    final count = (aggregate?.tryGet<int>('count') ?? 0) + fresh.length;
    if (count == 0) return null;

    final last = _sortedCandidates(
      replies,
      serverLatest,
      deletedIds,
    ).lastOrNull;
    return ThreadSummary._(
      rootEventId: root.eventId,
      replyCount: count,
      lastReply: last,
      lastReplyText: last == null ? null : _textWithEdit(last, liveEvents),
    );
  }

  static Map<String, Object?>? _aggregateOf(Event root) => root.unsigned
      ?.tryGetMap<String, Object?>('m.relations')
      ?.tryGetMap<String, Object?>('m.thread');

  static Set<String> _redactedIds(Iterable<Event> liveEvents) => {
    for (final e in liveEvents)
      if (e.redacted) e.eventId,
  };

  static List<Event> _liveReplies(Event root, Iterable<Event> liveEvents) =>
      liveEvents
          .where((e) => e.threadRootId == root.eventId && !e.redacted)
          .toList();

  static Event? _serverLatest(Map<String, Object?>? aggregate, Event root) {
    final latestJson = aggregate?.tryGetMap<String, Object?>('latest_event');
    return latestJson == null ? null : Event.fromJson(latestJson, root.room);
  }

  /// A live reply the server aggregate does not know yet.
  static bool _isFresh(Event e, Event? serverLatest) =>
      e.eventId != serverLatest?.eventId &&
      (serverLatest == null ||
          e.originServerTs.isAfter(serverLatest.originServerTs));

  /// Oldest first.
  static List<Event> _sortedCandidates(
    List<Event> replies,
    Event? serverLatest,
    Set<String> deletedIds,
  ) {
    // The live copy of the server latest reply (decrypted) replaces it.
    final liveLatest = replies.firstWhereOrNull(
      (e) => e.eventId == serverLatest?.eventId,
    );
    final keptServerLatest =
        serverLatest == null || deletedIds.contains(serverLatest.eventId)
        ? null
        : liveLatest ?? serverLatest;
    return [
      ?keptServerLatest,
      ...replies.where((e) => e.eventId != serverLatest?.eventId),
    ]..sort((a, b) => a.originServerTs.compareTo(b.originServerTs));
  }

  /// Text of [last] as the card shows it: its latest valid edit applied,
  /// without the quote fallback a reply to another message carries.
  static String _textWithEdit(Event last, Iterable<Event> liveEvents) {
    // Matrix spec: only the sender can edit, and the edit is a message (an
    // undecrypted edit has no new content to show).
    final edits = liveEvents.where(
      (e) =>
          e.relationshipType == RelationshipTypes.edit &&
          e.relationshipEventId == last.eventId &&
          e.senderId == last.senderId &&
          e.type == EventTypes.Message,
    );
    final latestEdit = edits.isEmpty
        ? null
        : edits.reduce(
            (a, b) => b.originServerTs.isAfter(a.originServerTs) ? b : a,
          );
    return (latestEdit ?? last).calcUnlocalizedBody(
      hideReply: true,
      hideEdit: true,
    );
  }
}
