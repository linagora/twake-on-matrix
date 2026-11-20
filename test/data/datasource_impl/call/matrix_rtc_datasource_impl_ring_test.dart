import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports, the SDK does not export the type of its streams.
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:twake_chat/data/datasource_impl/call/matrix_rtc_datasource_impl.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_ring.dart';

const _room = CallRoom('!room:hs.test');
const _join = CallJoin(room: _room, serviceUrl: 'https://rtc.test');
const _videoJoin = CallJoin(
  room: _room,
  serviceUrl: 'https://rtc.test',
  isVideo: true,
);

const _ringType = 'org.matrix.msc4075.rtc.notification';
const _legacyRingType = 'org.matrix.msc4075.call.notify';
const _declineType = 'org.matrix.msc4310.rtc.decline';
const _stableDeclineType = 'm.rtc.decline';
const _memberType = 'org.matrix.msc3401.call.member';

class _FakeRoom extends Fake implements Room {
  var isEncrypted = false;

  @override
  String get id => '!room:hs.test';

  @override
  bool get encrypted => isEncrypted;

  /// The other user of a direct chat, null for a group.
  String? dmUser;

  /// What the server says of the room: the members who joined. Null when
  /// the server said nothing yet.
  int? joinedCount = 3;

  @override
  String? get directChatMatrixID => dmUser;

  @override
  bool get isDirectChat => dmUser != null;

  @override
  RoomSummary get summary => RoomSummary.fromJson({
    if (joinedCount case final count?) 'm.joined_member_count': count,
  });

  @override
  Membership get membership => Membership.join;

  @override
  String? get roomVersion => '10';

  @override
  Map<String, Map<String, StrippedStateEvent>> states = {};

  /// The states of a partial room still in the store: in [states] only once
  /// the room is loaded.
  Map<String, Map<String, StrippedStateEvent>>? notLoaded;

  /// When set, the room cannot be loaded from the store.
  Exception? loadFailure;

  @override
  Future<void> postLoad() async {
    if (loadFailure case final error?) throw error;
    states = {...states, ...?notLoaded};
    notLoaded = null;
  }
}

typedef _Sent = ({String roomId, String type, Map<String, Object?> content});

typedef _Who = ({String user, String device});

const _alice = (user: '@alice:hs.test', device: 'DEV');
const _bobHere = (user: '@bob:hs.test', device: 'DEV');
const _bobPhone = (user: '@bob:hs.test', device: 'PHONE');
const _bobThisDevice = (user: '@bob:hs.test', device: 'BOB');

/// An event received from the sync, with the defaults of a ring from Alice.
class _Incoming {
  String type = _ringType;
  Map<String, Object?> content = {};
  String id = r'$event';
  String sender = _alice.user;
  DateTime? at;
  String? stateKey;

  Event toEvent(Room room) => Event(
    content: content,
    type: type,
    eventId: id,
    senderId: sender,
    originServerTs: at ?? DateTime.now(),
    stateKey: stateKey,
    room: room,
  );
}

class _Ring {
  String id = r'$ring';
  String sender = _alice.user;
  String type = _ringType;
  DateTime? at;
  Map<String, Object?> extra = {};
  String intent = 'video';

  _Incoming get incoming => _Incoming()
    ..type = type
    ..id = id
    ..sender = sender
    ..at = at
    ..content = {
      'slot_id': 'm.call#',
      if (type == _legacyRingType)
        'notify_type': 'ring'
      else
        'notification_type': 'ring',
      'm.call.intent': intent,
      'm.mentions': {
        'user_ids': [_bobHere.user],
      },
      // A legacy `call.notify` has no sender_ts.
      if (type != _legacyRingType)
        'sender_ts': (at ?? DateTime.now()).millisecondsSinceEpoch,
      ...extra,
    };
}

class _Decline {
  String ringId = r'$ring';
  String sender = _bobHere.user;
  String type = _declineType;

  _Incoming get incoming => _Incoming()
    ..type = type
    ..id = r'$decline'
    ..sender = sender
    ..content = {
      'm.relates_to': {'rel_type': 'm.reference', 'event_id': ringId},
    };
}

/// A push rule as the tests describe it.
typedef _RuleSpec = ({
  String id,
  List<Object?> actions,
  List<Map<String, Object?>> conditions,
});

typedef _PushRule = ({
  PushRuleKind kind,
  String id,
  List<Object?> actions,
  List<Map<String, Object?>> conditions,
});

class _FakeClient extends Fake implements Client {
  final room = _FakeRoom();
  final sent = <_Sent>[];
  final pushRules = <_PushRule>[];
  PushRuleSet? rules;

  /// When set, the server refuses what is sent: messages and push rules.
  Exception? failure;

  /// False: the room is unknown to the client, as after a sync that lost it.
  var knowsRoom = true;

  @override
  final CachedStreamController<Event> onTimelineEvent =
      CachedStreamController();

  @override
  final CachedStreamController<SyncUpdate> onSync = CachedStreamController();

  @override
  String? get userID => '@bob:hs.test';

  @override
  String? get deviceID => 'BOB';

  @override
  Room? getRoomById(String id) => knowsRoom ? room : null;

  @override
  String generateUniqueTransactionId() => 'txn';

  @override
  Future<String> sendMessage(
    String roomId,
    String eventType,
    String txnId,
    Map<String, Object?> body,
  ) async {
    if (failure case final error?) throw error;
    sent.add((roomId: roomId, type: eventType, content: body));
    return r'$sent';
  }

  @override
  PushRuleSet? get globalPushRules => rules;

  @override
  Future<void> setPushRule(
    PushRuleKind kind,
    String ruleId,
    List<Object?> actions, {
    String? before,
    String? after,
    List<PushCondition>? conditions,
    String? pattern,
  }) async {
    if (failure case final error?) throw error;
    pushRules.add((
      kind: kind,
      id: ruleId,
      actions: actions,
      conditions: [for (final c in conditions ?? <PushCondition>[]) c.toJson()],
    ));
  }

  void receive(_Incoming incoming) =>
      onTimelineEvent.add(incoming.toEvent(room));

  void ring([_Ring? ring]) => receive((ring ?? _Ring()).incoming);

  void decline([_Decline? decline]) =>
      receive((decline ?? _Decline()).incoming);

  void membership(_Who who) => receive(
    _Incoming()
      ..type = _memberType
      ..id = r'$member'
      ..sender = who.user
      ..stateKey = '_${who.user}_${who.device}_m.call'
      ..content = {'application': 'm.call', 'device_id': who.device},
  );
}

StrippedStateEvent _member(_Who who, {Map<String, Object?>? content}) =>
    StrippedStateEvent(
      type: _memberType,
      senderId: who.user,
      stateKey: '_${who.user}_${who.device}_m.call',
      content: content ?? {'application': 'm.call', 'device_id': who.device},
    );

/// The call members of a room state.
Map<String, Map<String, StrippedStateEvent>> _callMembers(
  List<StrippedStateEvent> members,
) => {
  _memberType: {for (final member in members) member.stateKey!: member},
};

/// A membership as the room state holds it once synced, with its server time.
Event _memberEvent(
  _Who who, {
  required DateTime at,
  Map<String, Object?>? content,
}) => Event(
  content: content ?? {'application': 'm.call', 'device_id': who.device},
  type: _memberType,
  eventId: r'$state',
  senderId: who.user,
  originServerTs: at,
  stateKey: '_${who.user}_${who.device}_m.call',
  room: _FakeRoom(),
);

void main() {
  late _FakeClient client;
  late MatrixRtcDatasourceImpl datasource;

  setUp(() {
    client = _FakeClient();
    datasource = MatrixRtcDatasourceImpl(client);
  });

  group('sendRing', () {
    test(
      'in a direct chat the ring names the other user, not the room',
      () async {
        client.room
          ..dmUser = _alice.user
          ..joinedCount = 2;
        final before = DateTime.now().millisecondsSinceEpoch;

        await datasource.sendRing(_videoJoin, membershipEventId: r'$member');

        final after = DateTime.now().millisecondsSinceEpoch;
        final sent = client.sent.single;
        expect(sent.roomId, '!room:hs.test');
        expect(sent.type, 'org.matrix.msc4075.rtc.notification');
        final senderTs = sent.content['sender_ts'];
        expect(senderTs, isA<int>());
        expect(senderTs as int, inInclusiveRange(before, after));
        final mentions = sent.content['m.mentions']! as Map;
        expect(mentions['user_ids'], [_alice.user]);
        expect(mentions['room'], isNot(true));
        expect(
          {...sent.content}
            ..remove('sender_ts')
            ..remove('m.mentions'),
          {
            'slot_id': 'm.call#ROOM',
            'notification_type': 'ring',
            'lifetime': 60000,
            'm.relates_to': {'rel_type': 'm.reference', 'event_id': r'$member'},
            'm.call.intent': 'video',
          },
        );
      },
    );

    // `m.direct` alone does not say who is in the room: a third member may
    // have joined it.
    final callees = <String, ({String? dmUser, int? joined, String? callee})>{
      'a direct chat of two rings the other user': (
        dmUser: _alice.user,
        joined: 2,
        callee: _alice.user,
      ),
      'a direct chat whose members the server did not count rings the other '
          'user': (
        dmUser: _alice.user,
        joined: null,
        callee: _alice.user,
      ),
      'a direct chat with a third member is notified, nobody rung': (
        dmUser: _alice.user,
        joined: 3,
        callee: null,
      ),
      'a group of more than two is notified, nobody rung': (
        dmUser: null,
        joined: 3,
        callee: null,
      ),
    };

    callees.forEach((name, expected) {
      test(name, () async {
        client.room
          ..dmUser = expected.dmUser
          ..joinedCount = expected.joined;

        await datasource.sendRing(_join, membershipEventId: r'$member');

        final content = client.sent.single.content;
        expect(
          content['notification_type'],
          expected.callee == null ? 'notification' : 'ring',
        );
        final mentions = content['m.mentions']! as Map;
        expect(mentions['user_ids'], [?expected.callee]);
        expect(mentions['room'], isNot(true));
      });
    });

    test('an audio call says so in its intent', () async {
      await datasource.sendRing(_join, membershipEventId: r'$member');

      expect(client.sent.single.content['m.call.intent'], 'audio');
    });

    test('the ring goes out in the clear, whatever the room', () async {
      client.room.isEncrypted = true;

      await datasource.sendRing(_join, membershipEventId: r'$member');

      // `Room.sendEvent` would encrypt it (and the fake room has no such
      // method): the ring is sent as it is.
      expect(client.sent.single.type, 'org.matrix.msc4075.rtc.notification');
    });
  });

  group('hasOtherMembers', () {
    test('someone else in the call of the room', () {
      client.room.states = {
        _memberType: {'a': _member(_alice)},
      };

      expect(datasource.hasOtherMembers(_room), isTrue);
    });

    test('nobody, or only this device, is nobody else', () {
      expect(datasource.hasOtherMembers(_room), isFalse);

      client.room.states = {
        _memberType: {'a': _member(_bobThisDevice)},
      };
      expect(datasource.hasOtherMembers(_room), isFalse);
    });

    test('the user on another device is already in the call', () {
      client.room.states = {
        _memberType: {'a': _member(_bobPhone)},
      };

      expect(datasource.hasOtherMembers(_room), isTrue);
    });

    test('another user on a device with the id of this one counts', () {
      client.room.states = {
        _memberType: {'a': _member((user: _alice.user, device: 'BOB'))},
      };

      expect(datasource.hasOtherMembers(_room), isTrue);
    });

    test('a membership without created_ts expires from its server time', () {
      final longAgo = DateTime.now().subtract(const Duration(hours: 5));
      client.room.states = {
        _memberType: {
          'a': _memberEvent(
            _alice,
            at: longAgo,
            content: {
              'application': 'm.call',
              'device_id': 'DEV',
              'expires': 14400000,
            },
          ),
        },
      };

      expect(datasource.hasOtherMembers(_room), isFalse);
    });

    test('a recent membership without created_ts is in the call', () {
      client.room.states = {
        _memberType: {
          'a': _memberEvent(
            _alice,
            at: DateTime.now(),
            content: {
              'application': 'm.call',
              'device_id': 'DEV',
              'expires': 14400000,
            },
          ),
        },
      };

      expect(datasource.hasOtherMembers(_room), isTrue);
    });

    test('someone who left is not in the call', () {
      client.room.states = {
        _memberType: {'a': _member(_alice, content: {})},
      };

      expect(datasource.hasOtherMembers(_room), isFalse);
    });

    test('a membership past its expiry is not in the call', () {
      final longAgo = DateTime.now()
          .subtract(const Duration(hours: 5))
          .millisecondsSinceEpoch;
      client.room.states = {
        _memberType: {
          'a': _member(
            _alice,
            content: {
              'application': 'm.call',
              'device_id': 'DEV',
              'created_ts': longAgo,
              'expires': 14400000,
            },
          ),
        },
      };

      expect(datasource.hasOtherMembers(_room), isFalse);
    });
  });

  group('declineRing', () {
    CallRing ring() => CallRing(
      eventId: r'$ring',
      room: _room,
      senderId: '@alice:hs.test',
      isVideo: true,
      expiresAt: DateTime.now().add(const Duration(seconds: 30)),
    );

    test('the decline relates to the ring and holds nothing else', () async {
      await datasource.declineRing(ring());

      final sent = client.sent.single;
      expect(sent.roomId, '!room:hs.test');
      expect(sent.type, 'org.matrix.msc4310.rtc.decline');
      expect(sent.content, {
        'm.relates_to': {'rel_type': 'm.reference', 'event_id': r'$ring'},
      });
    });

    test('the ring declined here stops at once', () {
      fakeAsync((async) {
        final lists = <List<CallRing>>[];
        datasource.watchRings().listen(lists.add);
        async.flushMicrotasks();
        client.ring();
        async.flushMicrotasks();
        expect(lists.last, hasLength(1));

        datasource.declineRing(lists.last.single);
        async.flushMicrotasks();

        expect(lists.last, isEmpty);
      });
    });
  });

  group('watchRings', () {
    late List<List<CallRing>> lists;

    void listen(FakeAsync async) {
      lists = [];
      datasource.watchRings().listen(lists.add);
      async.flushMicrotasks();
    }

    Iterable<CallRing> everRung() => lists.expand((rings) => rings);

    test('a ring of someone else rings, until it lapses', () {
      fakeAsync((async) {
        listen(async);
        final at = DateTime.now();

        client.ring(_Ring()..at = at);
        async.flushMicrotasks();

        final ring = lists.last.single;
        expect(ring.eventId, r'$ring');
        expect(ring.room, _room);
        expect(ring.senderId, '@alice:hs.test');
        expect(ring.isVideo, isTrue);
        expect(ring.expiresAt.difference(at), const Duration(seconds: 60));

        async.elapse(const Duration(seconds: 61));

        expect(lists.last, isEmpty);
      });
    });

    test('an audio call does not ring as a video call', () {
      fakeAsync((async) {
        listen(async);

        client.ring(_Ring()..intent = 'audio');
        async.flushMicrotasks();

        expect(lists.last.single.isVideo, isFalse);
      });
    });

    test('the ring of the user is not for the user', () {
      fakeAsync((async) {
        listen(async);

        client.ring(_Ring()..sender = _bobHere.user);
        async.flushMicrotasks();

        expect(everRung(), isEmpty);
      });
    });

    test('a ring already past its lifetime never rings', () {
      fakeAsync((async) {
        listen(async);

        client.ring(
          _Ring()..at = DateTime.now().subtract(const Duration(minutes: 2)),
        );
        async.flushMicrotasks();

        expect(everRung(), isEmpty);
      });
    });

    final lifetimes = <String, ({Map<String, Object?> extra, int seconds})>{
      'the lifetime of the sender counts': (
        extra: {'lifetime': 10000},
        seconds: 10,
      ),
      'the lifetime of the sender counts, up to 120 s': (
        extra: {'lifetime': 3600000},
        seconds: 120,
      ),
      'a lifetime that is no number is 60 s': (
        extra: {'lifetime': 'forever'},
        seconds: 60,
      ),
      'a sender_ts to come cannot make a ring last longer': (
        extra: {
          'sender_ts': DateTime.now()
              .add(const Duration(hours: 1))
              .millisecondsSinceEpoch,
        },
        seconds: 60,
      ),
    };

    lifetimes.forEach((name, expected) {
      test(name, () {
        fakeAsync((async) {
          listen(async);
          final at = DateTime.now();

          client.ring(
            _Ring()
              ..at = at
              ..extra = expected.extra,
          );
          async.flushMicrotasks();

          expect(
            lists.last.single.expiresAt.difference(at),
            Duration(seconds: expected.seconds),
          );
        });
      });
    });

    // A legacy `call.notify` has no sender_ts: the server time counts.
    final legacyRings = <String, ({Duration age, bool rings})>{
      'the earlier name of the ring, without sender_ts, rings too': (
        age: Duration.zero,
        rings: true,
      ),
      'an earlier ring sent long ago, without sender_ts, does not ring': (
        age: const Duration(minutes: 2),
        rings: false,
      ),
    };

    legacyRings.forEach((name, expected) {
      test(name, () {
        fakeAsync((async) {
          listen(async);
          final at = DateTime.now().subtract(expected.age);

          client.ring(
            _Ring()
              ..type = _legacyRingType
              ..at = at,
          );
          async.flushMicrotasks();

          expect([
            for (final ring in everRung()) ring.expiresAt.difference(at),
          ], expected.rings ? [const Duration(seconds: 60)] : isEmpty);
        });
      });
    });

    test('a ring on time by the server rings, whatever the sender clock', () {
      fakeAsync((async) {
        listen(async);
        // Received 20 s after the server time, with a sender clock 15 s
        // behind: on time by the server, past its lifetime by the sender.
        final at = DateTime.now().subtract(const Duration(seconds: 20));
        final senderTs = at.subtract(const Duration(seconds: 15));

        client.ring(
          _Ring()
            ..at = at
            ..extra = {
              'sender_ts': senderTs.millisecondsSinceEpoch,
              'lifetime': 30000,
            },
        );
        async.flushMicrotasks();

        expect(
          [for (final ring in everRung()) ring.expiresAt.difference(at)],
          [const Duration(seconds: 30)],
        );
      });
    });

    test('a notification that is not a ring does not ring', () {
      fakeAsync((async) {
        listen(async);

        client.receive(
          _Incoming()..content = {'notification_type': 'notification'},
        );
        client.receive(
          _Incoming()
            ..type = _legacyRingType
            ..content = {'notify_type': 'notify'},
        );
        async.flushMicrotasks();

        expect(everRung(), isEmpty);
      });
    });

    test('a content that makes no sense is ignored without failing', () {
      fakeAsync((async) {
        final errors = <Object>[];
        lists = [];
        datasource.watchRings().listen(lists.add, onError: errors.add);
        async.flushMicrotasks();

        client.receive(_Incoming());
        client.receive(_Incoming()..content = {'notification_type': 5});
        client.receive(
          _Incoming()
            ..id = r'$odd'
            ..content = {'notification_type': 'ring', 'm.call.intent': 7},
        );
        async.flushMicrotasks();

        expect(errors, isEmpty);
        expect(everRung().where((ring) => ring.eventId != r'$odd'), isEmpty);
      });
    });

    test('the decline of the user, here or elsewhere, stops the ring', () {
      for (final type in [_declineType, _stableDeclineType]) {
        fakeAsync((async) {
          listen(async);
          client.ring();
          async.flushMicrotasks();
          expect(lists.last, hasLength(1), reason: type);

          client.decline(_Decline()..type = type);
          async.flushMicrotasks();

          expect(lists.last, isEmpty, reason: type);
        });
      }
    });

    test('the decline of another callee does not stop the ring', () {
      fakeAsync((async) {
        listen(async);
        client.ring();
        async.flushMicrotasks();

        client.decline(_Decline()..sender = '@carol:hs.test');
        async.flushMicrotasks();

        expect(lists.last, hasLength(1));
      });
    });

    test('the decline of another ring leaves this one ringing', () {
      fakeAsync((async) {
        listen(async);
        client.ring();
        async.flushMicrotasks();

        client.decline(_Decline()..ringId = r'$other');
        async.flushMicrotasks();

        expect(lists.last, hasLength(1));
      });
    });

    test('joining the call, on any device, stops the ring of the room', () {
      fakeAsync((async) {
        listen(async);
        client.ring();
        async.flushMicrotasks();

        client.membership(_bobHere);
        async.flushMicrotasks();

        expect(lists.last, isEmpty);
      });
    });

    test('the membership of someone else leaves the ring', () {
      fakeAsync((async) {
        listen(async);
        client.ring();
        async.flushMicrotasks();

        client.membership(_alice);
        async.flushMicrotasks();

        expect(lists.last, hasLength(1));
      });
    });

    test('a ring that mentions only others does not ring', () {
      fakeAsync((async) {
        listen(async);

        client.ring(
          _Ring()
            ..extra = {
              'm.mentions': {
                'user_ids': ['@carol:hs.test'],
              },
            },
        );
        async.flushMicrotasks();

        expect(everRung(), isEmpty);
      });
    });

    test('a ring that mentions the room rings', () {
      fakeAsync((async) {
        listen(async);

        client.ring(
          _Ring()
            ..extra = {
              'm.mentions': {'user_ids': <String>[], 'room': true},
            },
        );
        async.flushMicrotasks();

        expect(lists.last.single.eventId, r'$ring');
      });
    });

    test('a ring that mentions nobody does not ring', () {
      fakeAsync((async) {
        listen(async);

        client.ring(_Ring()..extra = {'m.mentions': <String, Object?>{}});
        async.flushMicrotasks();

        expect(everRung(), isEmpty);
      });
    });

    test('an expired membership of this device does not silence a ring', () {
      fakeAsync((async) {
        final longAgo = DateTime.now()
            .subtract(const Duration(hours: 5))
            .millisecondsSinceEpoch;
        client.room.states = {
          _memberType: {
            'a': _member(
              _bobThisDevice,
              content: {
                'application': 'm.call',
                'device_id': 'BOB',
                'created_ts': longAgo,
                'expires': 14400000,
              },
            ),
          },
        };
        listen(async);

        client.ring();
        async.flushMicrotasks();

        expect(lists.last.single.eventId, r'$ring');
      });
    });

    test(
      'joining seen only in the room state (limited sync) ends the ring',
      () {
        fakeAsync((async) {
          listen(async);
          client.ring();
          async.flushMicrotasks();
          expect(lists.last, hasLength(1));

          client.room.states = {
            _memberType: {'a': _member(_bobPhone)},
          };
          client.onSync.add(SyncUpdate(nextBatch: 'next'));
          async.flushMicrotasks();

          expect(lists.last, isEmpty);
        });
      },
    );

    test('a call this device is already in does not ring', () {
      fakeAsync((async) {
        client.room.states = {
          _memberType: {'a': _member(_bobThisDevice)},
        };
        listen(async);

        client.ring();
        async.flushMicrotasks();

        expect(everRung(), isEmpty);
      });
    });
  });

  group('watchMissedCalls', () {
    late List<MissedCall> missed;

    void listen(FakeAsync async) {
      missed = [];
      datasource.watchMissedCalls().listen(missed.add);
      async.flushMicrotasks();
    }

    test('a ring that lapsed unanswered is a missed call', () {
      fakeAsync((async) {
        listen(async);
        final at = DateTime.now();
        client.ring(_Ring()..at = at);
        async.flushMicrotasks();
        expect(missed, isEmpty);

        async.elapse(const Duration(seconds: 61));

        final call = missed.single;
        expect(call.ringEventId, r'$ring');
        expect(call.room, _room);
        expect(call.callerId, '@alice:hs.test');
        expect(call.isVideo, isTrue);
        expect(
          call.sentAt.difference(at).abs(),
          lessThan(const Duration(seconds: 1)),
        );
      });
    });

    test('a ring the user declined is not missed', () {
      fakeAsync((async) {
        listen(async);
        client.ring();
        async.flushMicrotasks();
        client.decline();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 61));

        expect(missed, isEmpty);
      });
    });

    test('a call the user joined is not missed', () {
      fakeAsync((async) {
        listen(async);
        client.ring();
        async.flushMicrotasks();
        client.membership(_bobHere);
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 61));

        expect(missed, isEmpty);
      });
    });

    test('the ring of the user is no missed call of the user', () {
      fakeAsync((async) {
        listen(async);
        client.ring(_Ring()..sender = _bobHere.user);
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 61));

        expect(missed, isEmpty);
      });
    });

    test('a ring already lapsed when it arrives is not announced again', () {
      fakeAsync((async) {
        listen(async);

        client.ring(
          _Ring()..at = DateTime.now().subtract(const Duration(minutes: 5)),
        );
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 61));

        expect(missed, isEmpty);
      });
    });
  });

  group('a sync while it rings', () {
    late List<List<CallRing>> lists;
    late List<MissedCall> missed;

    void ring(FakeAsync async) {
      lists = [];
      missed = [];
      datasource.watchRings().listen(lists.add);
      datasource.watchMissedCalls().listen(missed.add);
      async.flushMicrotasks();
      client.ring();
      async.flushMicrotasks();
    }

    void sync(FakeAsync async) {
      client.onSync.add(SyncUpdate(nextBatch: 'next'));
      async.flushMicrotasks();
    }

    void syncWith(FakeAsync async, List<StrippedStateEvent> members) {
      client.room.states = _callMembers(members);
      sync(async);
    }

    Iterable<String> missedRings() => missed.map((call) => call.ringEventId);

    // Each sync gives the call members of the room state at that time.
    final cases =
        <
          String,
          ({
            List<List<StrippedStateEvent>> syncs,
            bool knowsRoom,
            bool ringsOn,
            bool missed,
          })
        >{
          'the caller still in the call: it rings on': (
            syncs: [
              [_member(_alice)],
            ],
            knowsRoom: true,
            ringsOn: true,
            missed: false,
          ),
          'the caller seen in the call, then gone: the ring stops, missed': (
            syncs: [
              [_member(_alice)],
              [_member(_alice, content: {})],
            ],
            knowsRoom: true,
            ringsOn: false,
            missed: true,
          ),
          'nobody seen in the call yet: it rings on to its end': (
            syncs: [
              [],
              [_member(_alice, content: {})],
            ],
            knowsRoom: true,
            ringsOn: true,
            missed: false,
          ),
          'the user joined on another device: the ring stops, not missed': (
            syncs: [
              [_member(_alice), _member(_bobPhone)],
            ],
            knowsRoom: true,
            ringsOn: false,
            missed: false,
          ),
          'a room the client does not know: it rings on': (
            syncs: [[]],
            knowsRoom: false,
            ringsOn: true,
            missed: false,
          ),
        };

    cases.forEach((name, expected) {
      test(name, () {
        fakeAsync((async) {
          ring(async);
          client.knowsRoom = expected.knowsRoom;

          for (final members in expected.syncs) {
            syncWith(async, members);
          }

          expect(lists.last, hasLength(expected.ringsOn ? 1 : 0));
          expect(missedRings(), [if (expected.missed) r'$ring']);

          // A ring that stopped is never missed again when it lapses; one
          // that rings on is missed at its end.
          async.elapse(const Duration(seconds: 61));
          expect(
            missed,
            hasLength(expected.missed || expected.ringsOn ? 1 : 0),
          );
        });
      });
    });

    test('a partial room is loaded before its call is judged', () {
      fakeAsync((async) {
        ring(async);
        // Only the store knows that the user joined on another device.
        client.room.notLoaded = _callMembers([
          _member(_alice),
          _member(_bobPhone),
        ]);

        sync(async);

        expect(lists.last, isEmpty);
        expect(missedRings(), isEmpty);
      });
    });

    test('a room that cannot be loaded leaves the ring ringing', () {
      fakeAsync((async) {
        ring(async);
        syncWith(async, [_member(_alice)]);
        client.room.loadFailure = Exception('store closed');

        syncWith(async, [_member(_alice, content: {})]);

        expect(lists.last, hasLength(1));
        expect(missedRings(), isEmpty);
        async.elapse(const Duration(seconds: 61));
        expect(missedRings(), [r'$ring']);
      });
    });
  });

  group('ensureCallRingPushRules', () {
    const ringConditions = [
      {
        'kind': 'event_match',
        'key': 'type',
        'pattern': 'org.matrix.msc4075.rtc.notification',
      },
      {
        'kind': 'event_match',
        'key': 'content.notification_type',
        'pattern': 'ring',
      },
    ];
    const legacyConditions = [
      {
        'kind': 'event_match',
        'key': 'type',
        'pattern': 'org.matrix.msc4075.call.notify',
      },
      {'kind': 'event_match', 'key': 'content.notify_type', 'pattern': 'ring'},
    ];
    const ringActions = [
      'notify',
      {'set_tweak': 'sound', 'value': 'ring'},
    ];

    const ringRule = (
      id: 'app.twake.chat.call_ring',
      actions: ringActions,
      conditions: ringConditions,
    );
    const legacyRule = (
      id: 'app.twake.chat.call_ring_legacy',
      actions: ringActions,
      conditions: legacyConditions,
    );

    PushRule rule(_RuleSpec spec) => PushRule(
      actions: spec.actions,
      conditions: [for (final c in spec.conditions) PushCondition.fromJson(c)],
      default$: false,
      enabled: true,
      ruleId: spec.id,
    );

    test('a session without the rules gets both, as underride rules', () async {
      client.rules = PushRuleSet(underride: []);

      await datasource.ensureCallRingPushRules();

      expect(
        {
          for (final r in client.pushRules)
            r.id: {
              'kind': r.kind,
              'actions': r.actions,
              'conditions': r.conditions,
            },
        },
        {
          for (final r in [ringRule, legacyRule])
            r.id: {
              'kind': PushRuleKind.underride,
              'actions': r.actions,
              'conditions': r.conditions,
            },
        },
      );
    });

    test('push rules not synced yet: the rules are set all the same', () async {
      client.rules = null;

      await datasource.ensureCallRingPushRules();

      expect(client.pushRules.map((r) => r.id), [
        'app.twake.chat.call_ring',
        'app.twake.chat.call_ring_legacy',
      ]);
    });

    const otherActions = (
      id: 'app.twake.chat.call_ring',
      actions: ['notify'],
      conditions: ringConditions,
    );
    final otherConditions = (
      id: ringRule.id,
      actions: ringActions,
      conditions: [ringConditions.first],
    );

    // A rule already there belongs to whoever set it: it is never rewritten.
    final present = <String, ({List<_RuleSpec> there, List<String> added})>{
      'rules already there, as they should be, cost no request': (
        there: [ringRule, legacyRule],
        added: [],
      ),
      'a rule with other actions is left as it is': (
        there: [otherActions, legacyRule],
        added: [],
      ),
      'a rule with other conditions is left as it is': (
        there: [otherConditions, legacyRule],
        added: [],
      ),
      'only the missing rule is added, the one that differs left alone': (
        there: [otherActions],
        added: [legacyRule.id],
      ),
    };

    present.forEach((name, expected) {
      test(name, () async {
        client.rules = PushRuleSet(
          underride: [for (final spec in expected.there) rule(spec)],
        );

        await datasource.ensureCallRingPushRules();

        expect(client.pushRules.map((r) => r.id), expected.added);
      });
    });
  });

  group('when the server refuses', () {
    final actions = <String, Future<void> Function(MatrixRtcDatasourceImpl)>{
      'a ring not sent is logged and reported to the caller': (datasource) =>
          datasource.sendRing(_videoJoin, membershipEventId: r'$member'),
      'push rules not set are logged and reported to the caller':
          (datasource) => datasource.ensureCallRingPushRules(),
    };

    actions.forEach((name, act) {
      test(name, () async {
        client
          ..room.dmUser = _alice.user
          ..rules = PushRuleSet(underride: [])
          ..failure = Exception('M_FORBIDDEN');
        Logs().outputEvents.clear();

        await expectLater(act(datasource), throwsA(isA<Exception>()));

        expect(
          Logs().outputEvents.where((event) => event.level == Level.warning),
          isNotEmpty,
        );
      });
    });
  });
}
