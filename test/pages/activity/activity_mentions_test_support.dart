import 'dart:async';

import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_mentions_repository.dart';

/// THR-M-12, slice 2: the mentions of the user, read from `/notifications`
/// (rooms and threads, the history not loaded included), as a test sets
/// them.
class FakeActivityMentionsRepository implements ActivityMentionsRepository {
  FakeActivityMentionsRepository({this.mentions = const []});

  List<ActivityItem> mentions;

  /// Set it to make the next reads fail.
  Object? error;

  /// Set it to hold the next read until it completes.
  Completer<void>? gate;

  int reads = 0;

  @override
  Future<List<ActivityItem>> getMentions() async {
    reads++;
    await gate?.future;
    final failure = error;
    if (failure != null) throw failure;
    return mentions;
  }
}

/// [author] mentioned the user in a room, or in the thread of [rootId].
ActivityItem mentionItem({
  required String roomId,
  required String roomName,
  required String eventId,
  required DateTime time,
  String author = 'Dan Brown',
  String text = '@me can you check?',
  String? rootId,
  String? rootText,
}) => ActivityItem(
  kind: ActivityKind.mention,
  roomId: roomId,
  roomName: roomName,
  time: time,
  authorName: author,
  quote: text,
  eventId: eventId,
  threadRootId: rootId,
  threadTitle: rootText,
);
