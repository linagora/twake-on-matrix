import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_rules.dart';

import '../../usecase/room/send_text_message_interactor_test.mocks.dart';

/// THR-M-07 and THR-M-09, P2: the local notification of a thread reply with
/// the explicit choice of the user (`app.twake.chat.thread_prefs`). A muted
/// thread notifies nothing, mentions included; an unfollowed thread is no
/// longer followed, even if the user wrote its root, but a mention in it
/// still notifies, as on the web; a followed thread notifies without taking
/// part. The push rules still decide first.
void main() {
  setUp(() {
    final client = MockClient();
    when(client.userID).thenReturn(_me);
    _room = MockRoom();
    when(_room.id).thenReturn('!team:example.org');
    when(_room.client).thenReturn(client);
    when(_room.receiptState).thenReturn(LatestReceiptState.empty());
    when(
      _room.getEventById(_rootId),
    ).thenAnswer((_) async => _root(_Author.me));
  });

  group('a muted thread', _mutedTests);
  group('an unfollowed thread', _unfollowedTests);
  group('a thread followed by choice', _followedTests);
}

const _rootId = r'$lunch';
const _me = '@me:example.org';
const _bob = '@bob:example.org';

late MockRoom _room;

final _notifies = EvaluatedPushRuleAction.fromActions(['notify']);
final _mention = EvaluatedPushRuleAction.fromActions([
  'notify',
  {'set_tweak': 'highlight'},
]);
final _silent = EvaluatedPushRuleAction.fromActions(['dont_notify']);

/// Who wrote the root of the thread.
enum _Author {
  me(_me),
  bob(_bob);

  const _Author(this.id);

  final String id;
}

Event _root(_Author author) => Event(
  type: EventTypes.Message,
  content: {'msgtype': 'm.text', 'body': 'Lunch on Friday?'},
  eventId: _rootId,
  senderId: author.id,
  originServerTs: DateTime.utc(2026, 11, 10, 9),
  room: _room,
);

Event _reply() => Event(
  type: EventTypes.Message,
  content: {
    'msgtype': 'm.text',
    'body': 'count me in',
    'm.relates_to': {
      'rel_type': RelationshipTypes.thread,
      'event_id': _rootId,
      'is_falling_back': true,
    },
  },
  eventId: r'$reply',
  senderId: _bob,
  originServerTs: DateTime.utc(2026, 11, 10, 10),
  room: _room,
);

/// What the push rules said, what the follow lookup says, and the choice.
class _Case {
  const _Case(this.choice, {required this.pushActions, this.followed = false});

  final ThreadPref? choice;
  final EvaluatedPushRuleAction pushActions;
  final FutureOr<bool?> followed;

  Future<bool> decide() => ThreadRules.shouldNotifyThreadReply(
    _reply(),
    followed: followed,
    pushActions: pushActions,
    choice: choice,
  );
}

void _mutedTests() {
  test('a reply does not notify, even in a thread the user follows', () async {
    final decision = _Case(
      ThreadPref.mute,
      pushActions: _notifies,
      followed: true,
    );

    expect(await decision.decide(), isFalse);
  });

  test('a mention does not notify', () async {
    expect(
      await _Case(ThreadPref.mute, pushActions: _mention).decide(),
      isFalse,
    );
  });
}

void _unfollowedTests() {
  test('a root the user wrote no longer makes a reply notify', () async {
    expect(
      await _Case(ThreadPref.unfollow, pushActions: _notifies).decide(),
      isFalse,
    );
  });

  test('a thread the user wrote in no longer notifies', () async {
    final decision = _Case(
      ThreadPref.unfollow,
      pushActions: _notifies,
      followed: true,
    );

    expect(await decision.decide(), isFalse);
  });

  test('a mention still notifies', () async {
    expect(
      await _Case(ThreadPref.unfollow, pushActions: _mention).decide(),
      isTrue,
    );
  });
}

void _followedTests() {
  setUp(
    () => when(
      _room.getEventById(_rootId),
    ).thenAnswer((_) async => _root(_Author.bob)),
  );

  test('a reply notifies, without waiting for the follow lookup', () async {
    final lookup = Completer<bool?>();
    final decision = _Case(
      ThreadPref.follow,
      pushActions: _notifies,
      followed: lookup.future,
    );

    expect(await decision.decide(), isTrue);
  });

  test('push rules that do not notify still win', () async {
    expect(
      await _Case(ThreadPref.follow, pushActions: _silent).decide(),
      isFalse,
    );
  });

  test('no choice: as before, a thread the user did not take part in does '
      'not notify', () async {
    expect(await _Case(null, pushActions: _notifies).decide(), isFalse);
  });
}
