import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/model/thread/thread_rules.dart';

import '../../usecase/room/send_text_message_interactor_test.mocks.dart';

/// Lot A of the review: 4515300590, 4515562011, and the « Minor » of review
/// 5829198697 on local_notifications_extension 54-66.
///
/// The push helper and the local notifications decide a thread reply with
/// one shared rule. The root of the thread (its sender: a root the user
/// wrote makes the thread followed) is loaded only when neither the follow
/// state nor a mention decided. A root that cannot be loaded counts as
/// unknown: the decision is made without it, nothing is thrown, so no
/// generic « New message » notification shows, even for the thread on
/// screen.
void main() {
  setUp(() {
    final client = MockClient();
    when(client.userID).thenReturn(_me);
    _room = MockRoom();
    when(_room.id).thenReturn(_roomId);
    when(_room.client).thenReturn(client);
    when(_room.receiptState).thenReturn(LatestReceiptState.empty());
    _rootFails();
  });

  group('the root is not loaded when something else decided', _noLookupTests);
  group('the root decides when nothing else did', _lookupTests);
  group('a root that cannot be loaded', _failingRootTests);
  group('the follow lookup of the thread still runs', _pendingFollowTests);
}

const _roomId = '!room:example.com';
const _rootId = r'$root';
const _me = '@me:example.com';
const _bob = '@bob:example.com';

late MockRoom _room;

const _thisThread = (roomId: _roomId, threadRootId: _rootId);

EvaluatedPushRuleAction _notifies() =>
    EvaluatedPushRuleAction.fromActions(['notify']);

EvaluatedPushRuleAction _mentionNotifies() =>
    EvaluatedPushRuleAction.fromActions([
      'notify',
      {'set_tweak': 'highlight'},
    ]);

EvaluatedPushRuleAction _silent() =>
    EvaluatedPushRuleAction.fromActions(['dont_notify']);

Event _reply({String sender = _bob}) => Event(
  type: EventTypes.Message,
  content: {
    'msgtype': 'm.text',
    'body': 'look',
    'm.relates_to': {
      'rel_type': RelationshipTypes.thread,
      'event_id': _rootId,
      'is_falling_back': true,
    },
  },
  eventId: r'$reply',
  senderId: sender,
  originServerTs: DateTime.utc(2026, 11, 9, 10),
  room: _room,
);

/// The server cannot give the root (not M_NOT_FOUND: the SDK rethrows).
void _rootFails() => when(_room.getEventById(_rootId)).thenAnswer(
  (_) async => throw MatrixException.fromJson({'errcode': 'M_UNKNOWN'}),
);

void _rootSentBy(String sender) => when(_room.getEventById(_rootId)).thenAnswer(
  (_) async => Event(
    type: EventTypes.Message,
    content: {'msgtype': 'm.text', 'body': 'root'},
    eventId: _rootId,
    senderId: sender,
    originServerTs: DateTime.utc(2026, 11, 9, 9),
    room: _room,
  ),
);

Future<bool> _decide({
  Event? reply,
  FutureOr<bool> followed = false,
  EvaluatedPushRuleAction? pushActions,
  ({String roomId, String threadRootId})? activeThread,
}) => ThreadRules.shouldNotifyThreadReply(
  reply ?? _reply(),
  followed: followed,
  pushActions: pushActions ?? _notifies(),
  activeThread: activeThread,
);

void _verifyRootNotLoaded() => verifyNever(_room.getEventById(any));

void _noLookupTests() {
  test('a followed thread notifies without loading the root', () async {
    expect(await _decide(followed: true), isTrue);
    _verifyRootNotLoaded();
  });

  test('a mention notifies without loading the root', () async {
    expect(await _decide(pushActions: _mentionNotifies()), isTrue);
    _verifyRootNotLoaded();
  });

  test('the push rules not notifying: no notification, no root', () async {
    expect(await _decide(pushActions: _silent()), isFalse);
    _verifyRootNotLoaded();
  });

  test('the thread on screen: no notification, no root', () async {
    expect(await _decide(activeThread: _thisThread), isFalse);
    _verifyRootNotLoaded();
  });

  test('the user\'s own reply: no notification, no root', () async {
    expect(await _decide(reply: _reply(sender: _me)), isFalse);
    _verifyRootNotLoaded();
  });
}

void _lookupTests() {
  test('a root the user wrote makes the reply notify', () async {
    _rootSentBy(_me);

    expect(await _decide(), isTrue);
    verify(_room.getEventById(_rootId)).called(1);
  });

  test(
    'a root of another user, thread not followed: no notification',
    () async {
      _rootSentBy(_bob);

      expect(await _decide(), isFalse);
    },
  );

  test('a root that is not found: no notification', () async {
    when(_room.getEventById(_rootId)).thenAnswer((_) async => null);

    expect(await _decide(), isFalse);
  });
}

void _failingRootTests() {
  test('counts as unknown: no notification, nothing thrown', () async {
    await expectLater(_decide(), completion(isFalse));
  });

  test('a mention still notifies', () async {
    await expectLater(
      _decide(pushActions: _mentionNotifies()),
      completion(isTrue),
    );
  });

  test('a followed thread still notifies', () async {
    await expectLater(_decide(followed: true), completion(isTrue));
  });

  test('the thread on screen shows nothing, also with a mention', () async {
    await expectLater(
      _decide(pushActions: _mentionNotifies(), activeThread: _thisThread),
      completion(isFalse),
    );
  });
}

/// Review 4515562072, maintainer decision of 09/11: in the foreground, a
/// reply that arrives while the follow lookup of its thread runs (neither
/// the follow state nor a mention decided) waits for the lookup. The root
/// cannot be loaded here, so only the lookup can decide.
void _pendingFollowTests() {
  late Completer<bool> lookup;
  setUp(() => lookup = Completer<bool>());

  test('the decision waits for the lookup', () async {
    var decided = false;
    final decision = _decide(
      followed: lookup.future,
    ).whenComplete(() => decided = true);
    await pumpEventQueue();

    expect(decided, isFalse);
    lookup.complete(true);
    expect(await decision, isTrue);
  });

  test('the user participated: the reply notifies', () async {
    final decision = _decide(followed: lookup.future);
    lookup.complete(true);

    expect(await decision, isTrue);
  });

  test('the user did not participate: no notification', () async {
    final decision = _decide(followed: lookup.future);
    lookup.complete(false);

    expect(await decision, isFalse);
  });

  test('the lookup fails: no notification, nothing thrown', () async {
    final decision = _decide(followed: lookup.future);
    await pumpEventQueue();
    lookup.completeError(MatrixException.fromJson({'errcode': 'M_UNKNOWN'}));

    await expectLater(decision, completion(isFalse));
  });

  test('a mention decides without waiting for the lookup', () async {
    var decided = false;
    final decision = _decide(
      followed: lookup.future,
      pushActions: _mentionNotifies(),
    ).whenComplete(() => decided = true);
    await pumpEventQueue();

    expect(decided, isTrue);
    expect(await decision, isTrue);
  });
}
