import 'dart:async';

import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_reactions_repository.dart';

/// THR-M-12, slice 3: the reactions of the others to the messages of the
/// user, from the history the client holds (50 at most, web D58), as a
/// test sets them.
class FakeActivityReactionsRepository implements ActivityReactionsRepository {
  FakeActivityReactionsRepository({List<ActivityItem> reactions = const []})
    : _reactions = [...reactions];

  List<ActivityItem> _reactions;
  final _changes = StreamController<List<ActivityItem>>.broadcast();

  @override
  Stream<List<ActivityItem>> watchReactions() async* {
    yield _reactions;
    yield* _changes.stream;
  }

  /// The sync brought a change: the reactions are now [reactions].
  void emit(List<ActivityItem> reactions) {
    _reactions = [...reactions];
    _changes.add(_reactions);
  }

  Future<void> close() => _changes.close();
}

/// [author] reacted [emoji] to the message [eventId] of the user.
class ReactionItem {
  const ReactionItem({
    required this.roomId,
    required this.roomName,
    required this.eventId,
    required this.time,
    this.author = 'Frank Moore',
    this.emoji = '👍',
    this.message = 'the deck is ready',
    this.rootId,
    this.rootText,
  });

  final String roomId;
  final String roomName;
  final String eventId;
  final DateTime time;
  final String author;
  final String emoji;
  final String message;
  final String? rootId;
  final String? rootText;

  ActivityItem get item => ActivityItem(
    kind: ActivityKind.reaction,
    roomId: roomId,
    roomName: roomName,
    time: time,
    authorName: author,
    quote: message,
    eventId: eventId,
    emoji: emoji,
    threadRootId: rootId,
    threadTitle: rootText,
  );
}
