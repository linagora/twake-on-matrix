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
    required bool participated,
    required String rootSenderId,
    required Set<String> replySenderIds,
  }) : _participated = participated,
       _rootSenderId = rootSenderId,
       _replySenderIds = replySenderIds;

  final String rootEventId;
  final int replyCount;
  final Event lastReply;

  /// Text of [lastReply] with its latest edit applied.
  final String lastReplyText;

  final bool _participated;
  final String _rootSenderId;
  final Set<String> _replySenderIds;

  /// P1: the user wrote the root, or replied in the thread.
  bool isFollowedBy(String userId) =>
      _participated ||
      _rootSenderId == userId ||
      _replySenderIds.contains(userId);

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

    final replies = liveEvents
        .where((e) => e.threadRootId == root.eventId && !e.redacted)
        .toList();
    final fresh = replies.where(
      (e) =>
          e.eventId != serverLatest?.eventId &&
          (serverLatest == null ||
              e.originServerTs.isAfter(serverLatest.originServerTs)),
    );
    final candidates = [?serverLatest, ...fresh]
      ..sort((a, b) => a.originServerTs.compareTo(b.originServerTs));
    if (candidates.isEmpty) return null;

    final count = (aggregate?.tryGet<int>('count') ?? 0) + fresh.length;
    if (count == 0) return null;

    final last = candidates.last;
    final edits = liveEvents.where(
      (e) =>
          e.relationshipType == RelationshipTypes.edit &&
          e.relationshipEventId == last.eventId,
    );
    final latestEdit = edits.isEmpty
        ? null
        : edits.reduce(
            (a, b) => b.originServerTs.isAfter(a.originServerTs) ? b : a,
          );
    final text =
        latestEdit?.content
            .tryGetMap<String, Object?>('m.new_content')
            ?.tryGet<String>('body') ??
        last.body;

    return ThreadSummary._(
      rootEventId: root.eventId,
      replyCount: count,
      lastReply: last,
      lastReplyText: text,
      participated:
          aggregate?.tryGet<bool>('current_user_participated') == true,
      rootSenderId: root.senderId,
      replySenderIds: {for (final e in replies) e.senderId},
    );
  }
}
