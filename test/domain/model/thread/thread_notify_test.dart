import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/model/thread/thread_rules.dart';

import '../../usecase/room/send_text_message_interactor_test.mocks.dart';

/// THR-M-09 and THR-M-06: the local notification of a thread reply.
///
/// With `unread_thread_notifications`, the room counters leave the thread
/// messages out, and the thread counters of a sync land on `onSync`, after
/// `onEvent` fired for its events. So the decision for a reply cannot wait
/// for any counter: it is made from the reply and the follow state.
void main() {
  setUp(() {
    final client = MockClient();
    when(client.userID).thenReturn(_me);
    _room = MockRoom();
    when(_room.id).thenReturn(_roomId);
    when(_room.client).thenReturn(client);
    // What the room says before the thread counters land.
    when(_room.notificationCount).thenReturn(0);
    when(_room.highlightCount).thenReturn(0);
    when(_room.pushRuleState).thenReturn(PushRuleState.notify);
    // Nothing read yet, unless a test says otherwise.
    when(_room.receiptState).thenReturn(LatestReceiptState.empty());
  });

  _basicTests();
  group('in a muted room', _mutedRoomTests);

  /// THR-M-09: a catch-up sync, or a reply read on another
  /// device, brings replies the user has read already. Their own receipt in
  /// the thread, or a newer unthreaded one, says so (MSC3771: a `main`
  /// receipt does not cover threads); the follow state and a mention do not
  /// bring the notification back.
  group('a reply the user has read already', _alreadyReadTests);

  /// THR-M-07 (P1: following = wrote the root or replied). On a
  /// new device the store knows no thread yet: a root the user wrote makes
  /// the thread followed for this decision. The caller passes the sender of
  /// the root (`rootSenderId`), which it reads from the root event.
  group('a thread whose root the user wrote', _ownRootTests);

  /// THR-M-09, maintainer decision (09/11) « push rules + filter »: what the
  /// push rules say for the reply comes first; the thread filter (followed,
  /// or a mention) only narrows it.
  group('the push rules decide first', _pushRulesFirstTests);
}

const _roomId = '!room:example.com';
const _rootId = r'$root';
const _me = '@me:example.com';
const _bot = '@bot:example.com';

late MockRoom _room;

/// When [_reply] was sent.
final _replySentAt = DateTime.utc(2026, 11, 8, 10);

const _later = Duration(minutes: 1);
final _before = _replySentAt.subtract(_later);
final _after = _replySentAt.add(_later);

LatestReceiptStateData _readAt(DateTime at) =>
    LatestReceiptStateData(r'$read', at.millisecondsSinceEpoch);

/// The user's own receipt, sent at [at].
LatestReceiptStateForTimeline _ownReceiptAt(DateTime at) =>
    LatestReceiptStateForTimeline(
      ownPrivate: null,
      ownPublic: _readAt(at),
      latestOwnReceipt: _readAt(at),
      otherUsers: {},
    );

void _receipts({
  DateTime? global,
  DateTime? main,
  Map<String, DateTime> byThread = const {},
  Map<String, DateTime> othersInThread = const {},
}) {
  when(_room.receiptState).thenReturn(
    LatestReceiptState(
      global: global == null
          ? LatestReceiptStateForTimeline.empty()
          : _ownReceiptAt(global),
      mainThread: main == null ? null : _ownReceiptAt(main),
      byThread: {
        for (final entry in byThread.entries)
          entry.key: _ownReceiptAt(entry.value),
        for (final entry in othersInThread.entries)
          entry.key: LatestReceiptStateForTimeline(
            ownPrivate: null,
            ownPublic: null,
            latestOwnReceipt: null,
            otherUsers: {'@alice:example.com': _readAt(entry.value)},
          ),
      },
    ),
  );
}

Event _reply({
  bool mentionsMe = false,
  String msgtype = MessageTypes.Text,
  String sender = '@bob:example.com',
}) => Event(
  type: EventTypes.Message,
  content: {
    'msgtype': msgtype,
    'body': mentionsMe ? 'Me: look' : 'look',
    if (mentionsMe) ...{
      'format': 'org.matrix.custom.html',
      'formatted_body': '<a href="https://matrix.to/#/$_me">Me</a>: look',
      'm.mentions': {
        'user_ids': [_me],
      },
    },
    'm.relates_to': {
      'rel_type': RelationshipTypes.thread,
      'event_id': _rootId,
      'is_falling_back': true,
    },
  },
  eventId: r'$reply',
  senderId: sender,
  originServerTs: _replySentAt,
  room: _room,
);

/// A notice of a bot.
Event _botNotice() => _reply(msgtype: MessageTypes.Notice, sender: _bot);

/// THR-M-09, maintainer decision (09/11) « push rules + filter »: the push
/// rules of the account decide first (`client.pushruleEvaluator.match`),
/// then the thread filter applies. The caller passes what they said.
///
/// The default rules (`.m.rule.message`): notify.
EvaluatedPushRuleAction _notifies() =>
    EvaluatedPushRuleAction.fromActions(['notify']);

/// A mention (`.m.rule.is_user_mention`, an override): notify and
/// highlight, also in a room set to mentions only.
EvaluatedPushRuleAction _mentionNotifies() =>
    EvaluatedPushRuleAction.fromActions([
      'notify',
      {'set_tweak': 'highlight'},
    ]);

/// No notification: a room set to mentions only (room rule), a muted room
/// (override), a notice of a bot (`.m.rule.suppress_notices`).
EvaluatedPushRuleAction _silent() =>
    EvaluatedPushRuleAction.fromActions(['dont_notify']);

/// The decision for [reply] (a plain [_reply] when null), with the push
/// rules saying [pushActions] (notify when null).
bool _shouldNotify({
  Event? reply,
  required bool followed,
  EvaluatedPushRuleAction? pushActions,
  String? rootSenderId,
  ({String roomId, String threadRootId})? activeThread,
}) => ThreadRules.shouldNotifyThreadEvent(
  reply ?? _reply(),
  followed: followed,
  pushActions: pushActions ?? _notifies(),
  rootSenderId: rootSenderId,
  activeThread: activeThread,
);

/// The decision for a reply that mentions the user, as the push rules see it.
bool _shouldNotifyMention({
  required bool followed,
  ({String roomId, String threadRootId})? activeThread,
}) => _shouldNotify(
  reply: _reply(mentionsMe: true),
  followed: followed,
  pushActions: _mentionNotifies(),
  activeThread: activeThread,
);

void _basicTests() {
  test('a reply in a followed thread notifies while the room counters are '
      'still 0', () {
    expect(_shouldNotify(followed: true), isTrue);
  });

  test('a reply that mentions the user notifies, in a thread they do not '
      'follow', () {
    expect(_shouldNotifyMention(followed: false), isTrue);
  });

  test('a reply in a thread the user does not follow, without mention, does '
      'not notify', () {
    expect(_shouldNotify(followed: false), isFalse);
  });

  test('a reply of the thread open on screen does not notify', () {
    expect(
      _shouldNotifyMention(
        followed: true,
        activeThread: (roomId: _roomId, threadRootId: _rootId),
      ),
      isFalse,
    );
  });

  test('a reply of another thread of the same room still notifies', () {
    expect(
      _shouldNotify(
        followed: true,
        activeThread: (roomId: _roomId, threadRootId: r'$other_root'),
      ),
      isTrue,
    );
  });
}

void _mutedRoomTests() {
  setUp(() {
    when(_room.pushRuleState).thenReturn(PushRuleState.mentionsOnly);
  });

  test('a reply in a followed thread does not notify', () {
    // The room rule of « mentions only ».
    expect(_shouldNotify(followed: true, pushActions: _silent()), isFalse);
  });

  test('a reply that mentions the user notifies', () {
    expect(_shouldNotifyMention(followed: false), isTrue);
  });
}

void _alreadyReadTests() {
  test('does not notify when the own receipt of the thread is on it', () {
    _receipts(byThread: {_rootId: _replySentAt});

    expect(_shouldNotifyMention(followed: true), isFalse);
  });

  test('does not notify when the own receipt of the thread is newer', () {
    _receipts(byThread: {_rootId: _after});

    expect(_shouldNotify(followed: true), isFalse);
  });

  test('does not notify when an unthreaded own receipt is newer than the '
      'one of the thread', () {
    _receipts(global: _after, byThread: {_rootId: _before});

    expect(_shouldNotify(followed: true), isFalse);
  });

  test('MSC3771: a newer own main receipt does not read a thread reply, '
      'which still notifies', () {
    // A `main` receipt covers the main timeline only; a thread reply is
    // read by the receipt of its thread or by an unthreaded one.
    _receipts(main: _after, byThread: {_rootId: _before});

    expect(_shouldNotify(followed: true), isTrue);
  });

  test('a newer reply than every own receipt still notifies', () {
    _receipts(global: _before, main: _before, byThread: {_rootId: _before});

    expect(_shouldNotify(followed: true), isTrue);
  });

  test('the own receipt of another thread does not read this one', () {
    _receipts(byThread: {r'$other_root': _after});

    expect(_shouldNotify(followed: true), isTrue);
  });

  test('the receipt of another user does not read it for the user', () {
    _receipts(othersInThread: {_rootId: _after});

    expect(_shouldNotify(followed: true), isTrue);
  });
}

void _ownRootTests() {
  test('notifies a reply although the store does not know the thread '
      'yet', () {
    expect(_shouldNotify(followed: false, rootSenderId: _me), isTrue);
  });

  test('a root of another user, in a thread not followed, does not '
      'notify', () {
    expect(
      _shouldNotify(followed: false, rootSenderId: '@alice:example.com'),
      isFalse,
    );
  });

  test('a reply already read does not notify', () {
    _receipts(byThread: {_rootId: _replySentAt});

    expect(_shouldNotify(followed: false, rootSenderId: _me), isFalse);
  });

  test('in a muted room, a reply without mention does not notify', () {
    when(_room.pushRuleState).thenReturn(PushRuleState.mentionsOnly);

    expect(
      _shouldNotify(
        followed: false,
        rootSenderId: _me,
        // The room rule of « mentions only ».
        pushActions: _silent(),
      ),
      isFalse,
    );
  });
}

void _pushRulesFirstTests() {
  test('a muted room: a reply that mentions the user does not notify', () {
    // « Mute »: an override rule without notify, above the mention rules.
    when(_room.pushRuleState).thenReturn(PushRuleState.dontNotify);

    expect(
      _shouldNotify(
        reply: _reply(mentionsMe: true),
        followed: true,
        pushActions: _silent(),
      ),
      isFalse,
    );
  });

  test('a notice of a bot the push rules do not notify, in a followed '
      'thread, does not notify', () {
    expect(
      _shouldNotify(
        reply: _botNotice(),
        followed: true,
        pushActions: _silent(),
      ),
      isFalse,
    );
  });

  test('a root the user wrote does not bring back a reply the push rules '
      'do not notify', () {
    expect(
      _shouldNotify(
        reply: _botNotice(),
        followed: false,
        rootSenderId: _me,
        pushActions: _silent(),
      ),
      isFalse,
    );
  });

  test('the default rules, a followed thread: the reply notifies', () {
    expect(_shouldNotify(followed: true, pushActions: _notifies()), isTrue);
  });

  test('the default rules, a thread not followed, no mention: the reply '
      'does not notify', () {
    expect(_shouldNotify(followed: false, pushActions: _notifies()), isFalse);
  });

  test('a reply the push rules highlight (a keyword, the display name) '
      'notifies in a thread not followed', () {
    // No `m.mentions`: the highlight of the push rules is the mention.
    expect(
      _shouldNotify(followed: false, pushActions: _mentionNotifies()),
      isTrue,
    );
  });
}
