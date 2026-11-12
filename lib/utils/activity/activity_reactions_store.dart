import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/utils/activity/activity_event_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_relation_extension.dart';

/// The reactions of the others to the messages of the user, among the events
/// the client saw live or in a history page in this session (nothing is kept
/// across a restart): the newest [maxReactions], a reaction taken back
/// dropped. The message a reaction is made to is found among the messages seen,
/// then on the device; for a live reaction only, then on the server: one
/// request per message (a miss is remembered), [maxServerLookups] per session,
/// one at a time.
class ActivityReactionsStore {
  ActivityReactionsStore(this._client);

  final Client _client;

  static const maxReactions = 50;

  /// The messages of the user seen, to tell what a reaction is made to.
  static const _maxMessages = 500;

  static const maxServerLookups = 20;

  /// The messages already asked of the server, found or not.
  final Set<String> _asked = {};

  final Map<String, Event> _messages = {};

  /// The reactions by the id of their event.
  final Map<String, ActivityItem> _reactions = {};
  final StreamController<List<ActivityItem>> _changes =
      StreamController.broadcast();
  Future<void> _queue = Future.value();

  /// Newest first.
  List<ActivityItem> get reactions =>
      _reactions.values.toList()..sort((a, b) => b.time.compareTo(a.time));

  Stream<List<ActivityItem>> get changes => _changes.stream;

  /// Takes an event of the live timeline or of a history page ([live] false),
  /// in order.
  void see(Event event, {bool live = true}) {
    _queue = _queue
        .then((_) => _handle(event, live))
        .catchError(
          (Object e, StackTrace s) =>
              Logs().w('Unable to read a reaction for the Activity', e, s),
        );
  }

  Future<void> _handle(Event event, bool live) async {
    if (event.type == EventTypes.Redaction) {
      if (_reactions.remove(event.redacts) != null) _changes.add(reactions);
    } else if (event.senderId == _client.userID) {
      if (event.type != EventTypes.Reaction) _rememberMessage(event);
    } else if (event.type == EventTypes.Reaction && !event.redacted) {
      await _addReaction(event, live);
    }
  }

  /// Logout: forgets everything.
  void clear() {
    _messages.clear();
    _asked.clear();
    _reactions.clear();
    _changes.add(const []);
  }

  void _rememberMessage(Event message) {
    _messages[message.eventId] = message;
    if (_messages.length > _maxMessages) {
      _messages.remove(_messages.keys.first);
    }
  }

  Future<Event?> _findTarget(Room room, String targetId, bool live) async {
    final stored = await _client.database.getEventById(targetId, room);
    if (stored != null || !live) return stored;
    if (_asked.length >= maxServerLookups || !_asked.add(targetId)) return null;
    try {
      return await room.getEventById(targetId);
    } catch (e) {
      Logs().w('Unable to read the message of a reaction', e);
      return null;
    }
  }

  Future<void> _addReaction(Event reaction, bool live) async {
    final targetId = reaction.relationshipEventId;
    final key = reaction.content
        .tryGetMap<String, Object?>('m.relates_to')
        ?.tryGet<String>('key');
    if (targetId == null || key == null) return;
    final target =
        _messages[targetId] ?? await _findTarget(reaction.room, targetId, live);
    if (target == null || target.senderId != _client.userID) return;
    _rememberMessage(target);
    final author = reaction.senderFromMemoryOrFallback;
    _reactions[reaction.eventId] = ActivityItem(
      kind: ActivityKind.reaction,
      roomId: reaction.room.id,
      roomName: reaction.room.getLocalizedDisplayname(),
      time: reaction.originServerTs,
      authorName: author.calcDisplayname(),
      authorAvatarUrl: author.avatarUrl,
      quote: target.activityText,
      eventId: target.eventId,
      threadRootId: target.threadRootId,
      emoji: key,
    );
    final newest = reactions;
    for (final dropped in newest.skip(maxReactions)) {
      _reactions.removeWhere((_, item) => item == dropped);
    }
    _changes.add(reactions);
  }
}

/// A client that keeps the reactions to its user ([TwakeClient]).
abstract interface class ActivityReactionsStoreOwner {
  ActivityReactionsStore get activityReactions;
}

extension ActivityReactionsClientExtension on Client {
  ActivityReactionsStore? get activityReactionsStore {
    final Object self = this;
    return self is ActivityReactionsStoreOwner ? self.activityReactions : null;
  }
}
