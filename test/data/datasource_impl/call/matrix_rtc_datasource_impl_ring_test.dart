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

  @override
  bool get isDirectChat => false;

  @override
  Membership get membership => Membership.join;

  @override
  String? get roomVersion => '10';

  @override
  Map<String, Map<String, StrippedStateEvent>> states = {};
}

class _Sent {
  _Sent(this.roomId, this.type, this.content);

  final String roomId;
  final String type;
  final Map<String, Object?> content;
}

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

  @override
  final CachedStreamController<Event> onTimelineEvent =
      CachedStreamController();

  @override
  String? get userID => '@bob:hs.test';

  @override
  String? get deviceID => 'BOB';

  @override
  Room? getRoomById(String id) => room;

  @override
  String generateUniqueTransactionId() => 'txn';

  @override
  Future<String> sendMessage(
    String roomId,
    String eventType,
    String txnId,
    Map<String, Object?> body,
  ) async {
    sent.add(_Sent(roomId, eventType, body));
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
    pushRules.add((
      kind: kind,
      id: ruleId,
      actions: actions,
      conditions: [for (final c in conditions ?? <PushCondition>[]) c.toJson()],
    ));
  }

  void receive({
    required String type,
    required Map<String, Object?> content,
    String id = r'$event',
    String sender = '@alice:hs.test',
    DateTime? at,
    String? stateKey,
  }) => onTimelineEvent.add(
    Event(
      content: content,
      type: type,
      eventId: id,
      senderId: sender,
      originServerTs: at ?? DateTime.now(),
      stateKey: stateKey,
      room: room,
    ),
  );

  void ring({
    String id = r'$ring',
    String sender = '@alice:hs.test',
    String type = _ringType,
    DateTime? at,
    Map<String, Object?> extra = const {},
    String intent = 'video',
  }) => receive(
    type: type,
    id: id,
    sender: sender,
    at: at,
    content: {
      'slot_id': 'm.call#',
      if (type == _legacyRingType)
        'notify_type': 'ring'
      else
        'notification_type': 'ring',
      'm.call.intent': intent,
      ...extra,
    },
  );

  void decline({
    String ringId = r'$ring',
    String sender = '@bob:hs.test',
    String type = _declineType,
  }) => receive(
    type: type,
    id: r'$decline',
    sender: sender,
    content: {
      'm.relates_to': {'rel_type': 'm.reference', 'event_id': ringId},
    },
  );

  void membership(String sender, {bool isInCall = true}) => receive(
    type: _memberType,
    id: r'$member',
    sender: sender,
    stateKey: '_${sender}_DEV_m.call',
    content: isInCall ? {'application': 'm.call', 'device_id': 'DEV'} : {},
  );
}

StrippedStateEvent _member(
  String userId, {
  Map<String, Object?>? content,
  String device = 'DEV',
}) => StrippedStateEvent(
  type: _memberType,
  senderId: userId,
  stateKey: '_${userId}_${device}_m.call',
  content: content ?? {'application': 'm.call', 'device_id': device},
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
      'the ring is an MSC4075 notification with a ring type, in the room',
      () async {
        final before = DateTime.now().millisecondsSinceEpoch;

        await datasource.sendRing(_videoJoin, membershipEventId: r'$member');

        final after = DateTime.now().millisecondsSinceEpoch;
        final sent = client.sent.single;
        expect(sent.roomId, '!room:hs.test');
        expect(sent.type, 'org.matrix.msc4075.rtc.notification');
        final senderTs = sent.content['sender_ts'];
        expect(senderTs, isA<int>());
        expect(senderTs as int, inInclusiveRange(before, after));
        expect({...sent.content}..remove('sender_ts'), {
          'slot_id': 'm.call#',
          'notification_type': 'ring',
          'lifetime': 60000,
          'm.mentions': {'user_ids': <String>[], 'room': true},
          'm.relates_to': {'rel_type': 'm.reference', 'event_id': r'$member'},
          'm.call.intent': 'video',
        });
      },
    );

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
        _memberType: {'a': _member('@alice:hs.test')},
      };

      expect(datasource.hasOtherMembers(_room), isTrue);
    });

    test('nobody, or only the user on another device', () {
      expect(datasource.hasOtherMembers(_room), isFalse);

      client.room.states = {
        _memberType: {'a': _member('@bob:hs.test', device: 'PHONE')},
      };
      expect(datasource.hasOtherMembers(_room), isFalse);
    });

    test('someone who left is not in the call', () {
      client.room.states = {
        _memberType: {'a': _member('@alice:hs.test', content: {})},
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
            '@alice:hs.test',
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

        client.ring(at: at);
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

        client.ring(intent: 'audio');
        async.flushMicrotasks();

        expect(lists.last.single.isVideo, isFalse);
      });
    });

    test('the ring of the user is not for the user', () {
      fakeAsync((async) {
        listen(async);

        client.ring(sender: '@bob:hs.test');
        async.flushMicrotasks();

        expect(everRung(), isEmpty);
      });
    });

    test('a ring already past its lifetime never rings', () {
      fakeAsync((async) {
        listen(async);

        client.ring(at: DateTime.now().subtract(const Duration(minutes: 2)));
        async.flushMicrotasks();

        expect(everRung(), isEmpty);
      });
    });

    test('the lifetime of the sender counts, up to 120 s', () {
      fakeAsync((async) {
        listen(async);
        final at = DateTime.now();

        client.ring(id: r'$short', at: at, extra: {'lifetime': 10000});
        client.ring(id: r'$long', at: at, extra: {'lifetime': 3600000});
        async.flushMicrotasks();

        final byId = {for (final ring in everRung()) ring.eventId: ring};
        expect(
          byId[r'$short']!.expiresAt.difference(at),
          const Duration(seconds: 10),
        );
        expect(
          byId[r'$long']!.expiresAt.difference(at),
          const Duration(seconds: 120),
        );
      });
    });

    test('a lifetime that is no number is 60 s', () {
      fakeAsync((async) {
        listen(async);
        final at = DateTime.now();

        client.ring(at: at, extra: {'lifetime': 'forever'});
        async.flushMicrotasks();

        expect(
          lists.last.single.expiresAt.difference(at),
          const Duration(seconds: 60),
        );
      });
    });

    test('a sender_ts to come cannot make a ring last longer', () {
      fakeAsync((async) {
        listen(async);
        final at = DateTime.now();
        final inAnHour = at.add(const Duration(hours: 1));

        client.ring(
          at: at,
          extra: {'sender_ts': inAnHour.millisecondsSinceEpoch},
        );
        async.flushMicrotasks();

        expect(
          lists.last.single.expiresAt.difference(at),
          const Duration(seconds: 60),
        );
      });
    });

    test('the earlier name of the ring rings too', () {
      fakeAsync((async) {
        listen(async);

        client.ring(type: _legacyRingType);
        async.flushMicrotasks();

        expect(lists.last.single.eventId, r'$ring');
      });
    });

    test('a notification that is not a ring does not ring', () {
      fakeAsync((async) {
        listen(async);

        client.receive(
          type: _ringType,
          content: {'notification_type': 'notification'},
        );
        client.receive(
          type: _legacyRingType,
          content: {'notify_type': 'notify'},
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

        client.receive(type: _ringType, content: {});
        client.receive(type: _ringType, content: {'notification_type': 5});
        client.receive(
          type: _ringType,
          content: {'notification_type': 'ring', 'm.call.intent': 7},
          id: r'$odd',
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

          client.decline(type: type);
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

        client.decline(sender: '@carol:hs.test');
        async.flushMicrotasks();

        expect(lists.last, hasLength(1));
      });
    });

    test('the decline of another ring leaves this one ringing', () {
      fakeAsync((async) {
        listen(async);
        client.ring();
        async.flushMicrotasks();

        client.decline(ringId: r'$other');
        async.flushMicrotasks();

        expect(lists.last, hasLength(1));
      });
    });

    test('joining the call, on any device, stops the ring of the room', () {
      fakeAsync((async) {
        listen(async);
        client.ring();
        async.flushMicrotasks();

        client.membership('@bob:hs.test');
        async.flushMicrotasks();

        expect(lists.last, isEmpty);
      });
    });

    test('the membership of someone else leaves the ring', () {
      fakeAsync((async) {
        listen(async);
        client.ring();
        async.flushMicrotasks();

        client.membership('@alice:hs.test');
        async.flushMicrotasks();

        expect(lists.last, hasLength(1));
      });
    });

    test('a call this device is already in does not ring', () {
      fakeAsync((async) {
        client.room.states = {
          _memberType: {'a': _member('@bob:hs.test', device: 'BOB')},
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
        client.ring(at: at);
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
        client.membership('@bob:hs.test');
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 61));

        expect(missed, isEmpty);
      });
    });

    test('the ring of the user is no missed call of the user', () {
      fakeAsync((async) {
        listen(async);
        client.ring(sender: '@bob:hs.test');
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 61));

        expect(missed, isEmpty);
      });
    });

    test('a ring already lapsed when it arrives is not announced again', () {
      fakeAsync((async) {
        listen(async);

        client.ring(at: DateTime.now().subtract(const Duration(minutes: 5)));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 61));

        expect(missed, isEmpty);
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

    PushRule rule(
      String id,
      List<Object?> actions,
      List<Map<String, Object?>> conditions,
    ) => PushRule(
      actions: actions,
      conditions: [for (final c in conditions) PushCondition.fromJson(c)],
      default$: false,
      enabled: true,
      ruleId: id,
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
          'app.twake.chat.call_ring': {
            'kind': PushRuleKind.underride,
            'actions': ringActions,
            'conditions': ringConditions,
          },
          'app.twake.chat.call_ring_legacy': {
            'kind': PushRuleKind.underride,
            'actions': ringActions,
            'conditions': legacyConditions,
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

    test('rules already there, as they should be, cost no request', () async {
      client.rules = PushRuleSet(
        underride: [
          rule('app.twake.chat.call_ring', ringActions, [...ringConditions]),
          rule('app.twake.chat.call_ring_legacy', ringActions, [
            ...legacyConditions,
          ]),
        ],
      );

      await datasource.ensureCallRingPushRules();

      expect(client.pushRules, isEmpty);
    });

    test('a rule that differs is replaced, the other left alone', () async {
      client.rules = PushRuleSet(
        underride: [
          rule('app.twake.chat.call_ring', ['notify'], [...ringConditions]),
          rule('app.twake.chat.call_ring_legacy', ringActions, [
            ...legacyConditions,
          ]),
        ],
      );

      await datasource.ensureCallRingPushRules();

      final replaced = client.pushRules.single;
      expect(replaced.id, 'app.twake.chat.call_ring');
      expect(replaced.kind, PushRuleKind.underride);
      expect(replaced.actions, ringActions);
      expect(replaced.conditions, ringConditions);
    });

    test('a rule with other conditions is replaced', () async {
      client.rules = PushRuleSet(
        underride: [
          rule('app.twake.chat.call_ring', ringActions, [ringConditions.first]),
          rule('app.twake.chat.call_ring_legacy', ringActions, [
            ...legacyConditions,
          ]),
        ],
      );

      await datasource.ensureCallRingPushRules();

      expect(client.pushRules.single.conditions, ringConditions);
    });
  });
}
