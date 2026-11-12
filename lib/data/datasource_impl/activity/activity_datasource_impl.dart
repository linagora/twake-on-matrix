import 'dart:async';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource/activity/activity_datasource.dart';
import 'package:twake_chat/utils/activity/activity_event_extension.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_resolved.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_summary.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

/// Reads the Activity tab from the sync data the client holds in memory.
class ActivityDatasourceImpl implements ActivityDatasource {
  ActivityDatasourceImpl(this._client);

  final Client? _client;

  /// The root of each followed thread, once asked: null when it could not be
  /// read (asked again with the next datasource).
  final Map<ThreadRef, Event?> _roots = {};
  final Set<ThreadRef> _fetching = {};
  final StreamController<void> _rootsRead = StreamController.broadcast();

  void dispose() => unawaited(_rootsRead.close());

  @override
  Stream<List<ActivityItem>> watchActivity() async* {
    final client = _client;
    if (client == null) {
      yield const [];
      return;
    }
    await _loaded(client);
    yield* _changes(client)
        .asyncMap((_) => _read(client))
        .distinct(const ListEquality<ActivityItem>().equals);
  }

  @override
  Stream<int> watchUnreadMentionCount() async* {
    final client = _client;
    if (client == null) {
      yield 0;
      return;
    }
    await _loaded(client);
    yield* _changes(client).map((_) => _unreadMentionCount(client)).distinct();
  }

  @override
  Future<void> markRoomRead(String roomId) async =>
      _client?.getRoomById(roomId)?.markRoomAndAllThreadsRead();

  /// The choices and rooms stored on the device are read: none when they
  /// cannot be.
  Future<void> _loaded(Client client) async {
    await client.accountDataLoading?.then((_) {}, onError: (_) {});
    await client.roomsLoading;
  }

  /// Now, then after each sync and each change of the thread counters,
  /// choices and resolved marks, and when a root has been read.
  Stream<void> _changes(Client client) {
    final store = client.threadUnread;
    return StreamGroup.merge([
      Stream<void>.value(null),
      client.onSync.stream,
      _rootsRead.stream,
      if (store != null)
        _notifications(Listenable.merge([store, store.resolvedChanges])),
    ]);
  }

  Stream<void> _notifications(Listenable source) {
    final controller = StreamController<void>();
    void notify() => controller.add(null);
    controller
      ..onListen = (() => source.addListener(notify))
      ..onCancel = (() {
        source.removeListener(notify);
        return controller.close();
      });
    return controller.stream;
  }

  int _unreadMentionCount(Client client) => client.rooms
      .where((room) => room.membership == Membership.join)
      .fold(0, (count, room) => count + room.highlightCountWithThreads);

  Future<List<ActivityItem>> _read(Client client) async {
    final rooms = client.rooms.where(
      (room) =>
          room.membership == Membership.join &&
          room.isNotSpaceAndStoryRoom() &&
          room.isUnreadWithThreads,
    );
    final threads = client.threadUnread?.followedThreads ?? const [];
    final items = [
      for (final room in rooms) _unreadRoomItem(room),
      for (final thread in threads) ?await _threadItem(client, thread),
    ];
    return items..sort((a, b) => b.time.compareTo(a.time));
  }

  ActivityItem _unreadRoomItem(Room room) {
    final last = room.lastEvent;
    final author = last?.senderFromMemoryOrFallback;
    return ActivityItem(
      kind: ActivityKind.unreadRoom,
      roomId: room.id,
      roomName: room.getLocalizedDisplayname(),
      time: last?.originServerTs ?? room.latestEventReceivedTime,
      authorName: author?.calcDisplayname() ?? '',
      authorAvatarUrl: author?.avatarUrl,
      quote: last?.activityText,
      unreadCount: room.unreadBadgeCount,
    );
  }

  /// Null while the root of the thread is being read.
  Future<ActivityItem?> _threadItem(Client client, ThreadRef thread) async {
    final room = client.getRoomById(thread.roomId);
    if (room == null) return null;
    if (!_roots.containsKey(thread)) {
      _fetchRoot(client, thread);
      return null;
    }
    final root = _roots[thread];
    if (root == null) return null;
    final store = client.threadUnread;
    final live = store?.latestReplyOf(thread);
    final summary = ThreadSummary.fromRoot(root, liveEvents: [?live]);
    final last = summary?.lastReply;
    if (summary == null || last == null) return null;
    final decrypted = await last.decryptedBy(client);
    final author = decrypted.senderFromMemoryOrFallback;
    return ActivityItem(
      kind: ActivityKind.reply,
      roomId: room.id,
      roomName: room.getLocalizedDisplayname(),
      time: last.originServerTs,
      authorName: author.calcDisplayname(),
      authorAvatarUrl: author.avatarUrl,
      quote: identical(decrypted, last)
          ? summary.lastReplyText
          : decrypted.activityText,
      unreadCount: store?.unreadCount(thread) ?? 0,
      eventId: last.eventId,
      threadRootId: thread.rootEventId,
      threadTitle: (await root.decryptedBy(client)).activityText,
      isResolved: room.isThreadResolved(thread.rootEventId),
    );
  }

  void _fetchRoot(Client client, ThreadRef thread) {
    if (!_fetching.add(thread)) return;
    client.threadUnread
        ?.threadRoot(thread)
        .then<Event?>(
          (root) => root,
          onError: (Object e, StackTrace s) {
            Logs().w('Unable to read the root of a followed thread', e, s);
            return null;
          },
        )
        .then((root) {
          _fetching.remove(thread);
          _roots[thread] = root;
          if (!_rootsRead.isClosed) _rootsRead.add(null);
        });
  }
}
