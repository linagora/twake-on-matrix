import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource/activity/activity_mentions_datasource.dart';
import 'package:twake_chat/utils/activity/activity_event_extension.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_rules.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

/// Reads the mentions from `/notifications`, which also covers the history
/// the client has not loaded. A mention is a notification the server
/// highlighted; an encrypted room the server cannot highlight has none.
class ActivityMentionsDatasourceImpl implements ActivityMentionsDatasource {
  const ActivityMentionsDatasourceImpl(this._client);

  final Client? _client;

  static const _limit = 50;

  @override
  Future<List<ActivityItem>> getMentions() async {
    final client = _client;
    if (client == null) return const [];
    final response = await client.getNotifications(
      only: 'highlight',
      limit: _limit,
    );
    final events = <Event>[
      for (final notification in response.notifications)
        if (client.getRoomById(notification.roomId) case final room?)
          await Event.fromMatrixEvent(
            notification.event,
            room,
          ).decryptedBy(client),
    ];
    final titles = await _rootTexts(client, events);
    return [for (final event in events) _item(event, titles)];
  }

  /// The text of the root of each thread the mentions are in.
  Future<Map<ThreadRef, String>> _rootTexts(
    Client client,
    List<Event> events,
  ) async {
    final threads = {
      for (final event in events)
        if (ThreadRules.threadRootOf(event) case final rootId?)
          ThreadRef(event.room.id, rootId),
    };
    final roots = await Future.wait([
      for (final thread in threads) _rootText(client, thread),
    ]);
    return {
      for (final (index, thread) in threads.indexed)
        if (roots[index] case final text?) thread: text,
    };
  }

  Future<String?> _rootText(Client client, ThreadRef thread) async {
    try {
      final root = await client.threadUnread?.threadRoot(thread);
      return (await root?.decryptedBy(client))?.activityText;
    } catch (e, s) {
      Logs().w('Unable to read the root of a thread with a mention', e, s);
      return null;
    }
  }

  ActivityItem _item(Event event, Map<ThreadRef, String> titles) {
    final rootId = ThreadRules.threadRootOf(event);
    final author = event.senderFromMemoryOrFallback;
    return ActivityItem(
      kind: ActivityKind.mention,
      roomId: event.room.id,
      roomName: event.room.getLocalizedDisplayname(),
      time: event.originServerTs,
      authorName: author.calcDisplayname(),
      authorAvatarUrl: author.avatarUrl,
      quote: event.activityText,
      eventId: event.eventId,
      threadRootId: rootId,
      threadTitle: rootId == null
          ? null
          : titles[ThreadRef(event.room.id, rootId)],
    );
  }
}
