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
    final aggregate = root.unsigned
        ?.tryGetMap<String, Object?>('m.relations')
        ?.tryGetMap<String, Object?>('m.thread');
    final latestJson = aggregate?.tryGetMap<String, Object?>('latest_event');
    final serverLatest = latestJson == null
        ? null
        : Event.fromJson(latestJson, root.room);

    // A redacted event loses its `m.relates_to`: match it by id.
    final deletedIds = {
      for (final e in liveEvents)
        if (e.redacted) e.eventId,
    };
    final replies = liveEvents
        .where((e) => e.threadRootId == root.eventId && !e.redacted)
        .toList();
    final fresh = replies.where(
      (e) =>
          e.eventId != serverLatest?.eventId &&
          (serverLatest == null ||
              e.originServerTs.isAfter(serverLatest.originServerTs)),
    );
    // The live copy of the server latest reply (decrypted) replaces it.
    final liveLatest = replies.firstWhereOrNull(
      (e) => e.eventId == serverLatest?.eventId,
    );
    final keptServerLatest =
        serverLatest == null || deletedIds.contains(serverLatest.eventId)
        ? null
        : liveLatest ?? serverLatest;
    final candidates = [
      ?keptServerLatest,
      ...replies.where((e) => e.eventId != serverLatest?.eventId),
    ]..sort((a, b) => a.originServerTs.compareTo(b.originServerTs));

    final count = (aggregate?.tryGet<int>('count') ?? 0) + fresh.length;
    if (count == 0) return null;

    final last = candidates.lastOrNull;
    final edits = last == null
        ? const <Event>[]
        : liveEvents.where(
            (e) =>
                e.relationshipType == RelationshipTypes.edit &&
                e.relationshipEventId == last.eventId,
          );
    final latestEdit = edits.isEmpty
        ? null
        : edits.reduce(
            (a, b) => b.originServerTs.isAfter(a.originServerTs) ? b : a,
          );

    return ThreadSummary._(
      rootEventId: root.eventId,
      replyCount: count,
      lastReply: last,
      lastReplyText: last == null
          ? null
          : latestEdit?.content
                    .tryGetMap<String, Object?>('m.new_content')
                    ?.tryGet<String>('body') ??
                last.body,
    );
  }
}
