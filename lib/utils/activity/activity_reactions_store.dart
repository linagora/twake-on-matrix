import 'dart:async';
import 'dart:collection';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/utils/activity/activity_event_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_rules.dart';

/// The reactions of the others to the messages of the user, among the events
/// the client saw live or in a history page in this session (nothing is kept
/// across a restart): the newest [maxReactions], a reaction taken back
/// dropped. The message a reaction is made to is found among the messages seen,
/// then on the device; for a live reaction only, then on the server: one
/// request per message ever (a miss is remembered), [maxServerLookups] per
/// [_budgetPeriod] (the budget comes back over time), one at a time. A
/// message found to be someone else's is remembered: its reactions read
/// neither the device nor the server.
class ActivityReactionsStore {
  ActivityReactionsStore(this._client, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Client _client;
  final DateTime Function() _now;

  static const maxReactions = 50;

  /// The messages of the user seen, to tell what a reaction is made to.
  static const _maxMessages = 500;

  static const maxServerLookups = 20;
  static const _budgetPeriod = Duration(minutes: 10);

  /// The messages already asked of the server, found or not.
  final Set<String> _asked = {};

  /// When the server was asked, within [_budgetPeriod].
  final Queue<DateTime> _lookups = Queue();

  /// The messages found to be someone else's.
  final Set<String> _foreign = {};

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
    _lookups.clear();
    _foreign.clear();
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
    if (!_mayAsk(targetId)) return null;
    try {
      return await room.getEventById(targetId);
    } catch (e) {
      Logs().w('Unable to read the message of a reaction', e);
      return null;
    }
  }

  /// Whether the server may be asked for [targetId] now: not asked before,
  /// and the budget is not spent. A message refused for want of budget is not
  /// remembered: it is asked at its next reaction.
  bool _mayAsk(String targetId) {
    if (_asked.contains(targetId)) return false;
    final now = _now();
    _lookups.removeWhere((at) => now.difference(at) >= _budgetPeriod);
    if (_lookups.length >= maxServerLookups) return false;
    _lookups.add(now);
    return _asked.add(targetId);
  }

  /// The message of the user a reaction is made to; null when it is someone
  /// else's (remembered) or cannot be found.
  Future<Event?> _myTarget(Room room, String targetId, bool live) async {
    final target =
        _messages[targetId] ?? await _findTarget(room, targetId, live);
    if (target == null) return null;
    if (target.senderId == _client.userID) return target;
    _foreign.add(targetId);
    return null;
  }

  Future<void> _addReaction(Event reaction, bool live) async {
    final targetId = reaction.relationshipEventId;
    final key = reaction.content
        .tryGetMap<String, Object?>('m.relates_to')
        ?.tryGet<String>('key');
    if (targetId == null || key == null) return;
    if (_foreign.contains(targetId)) return;
    final target = await _myTarget(reaction.room, targetId, live);
    if (target == null) return;
    _rememberMessage(target);
    _reactions[reaction.eventId] = _item(reaction, target, key);
    final newest = reactions;
    for (final dropped in newest.skip(maxReactions)) {
      _reactions.removeWhere((_, item) => item == dropped);
    }
    _changes.add(reactions);
  }

  ActivityItem _item(Event reaction, Event target, String key) {
    final author = reaction.senderFromMemoryOrFallback;
    return ActivityItem(
      kind: ActivityKind.reaction,
      roomId: reaction.room.id,
      roomName: reaction.room.getLocalizedDisplayname(),
      time: reaction.originServerTs,
      authorName: author.calcDisplayname(),
      authorAvatarUrl: author.avatarUrl,
      quote: target.activityText,
      eventId: target.eventId,
      threadRootId: ThreadRules.threadRootOf(target),
      emoji: key,
    );
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
