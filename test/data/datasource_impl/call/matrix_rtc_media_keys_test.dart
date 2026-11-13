import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports, the SDK does not export the type of its streams.
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:twake_chat/data/datasource_impl/call/matrix_rtc_media_keys.dart';
import 'package:twake_chat/domain/model/call/call_media_key.dart';

void main() {
  const alice = (userId: '@alice:hs', deviceId: 'A', createdTs: 1);
  const bob = (userId: '@bob:hs', deviceId: 'B', createdTs: 2);
  const bobAgain = (userId: '@bob:hs', deviceId: 'B', createdTs: 3);

  group('plan', () {
    test('a joiner gets the current key while it is recent', () {
      final plan = MatrixRtcMediaKeys.plan(
        sharedWith: {alice},
        members: {alice, bob},
        keyAge: const Duration(seconds: 3),
      );

      expect(plan.rotates, isFalse);
      expect(plan.recipients, {bob});
    });

    test('a joiner of an old key makes a new key for everyone', () {
      final plan = MatrixRtcMediaKeys.plan(
        sharedWith: {alice},
        members: {alice, bob},
        keyAge: const Duration(seconds: 30),
      );

      expect(plan.rotates, isTrue);
      expect(plan.recipients, {alice, bob});
    });

    test('a leaver makes a new key for those who stay', () {
      final plan = MatrixRtcMediaKeys.plan(
        sharedWith: {alice, bob},
        members: {alice},
        keyAge: const Duration(seconds: 1),
      );

      expect(plan.rotates, isTrue);
      expect(plan.recipients, {alice});
    });

    test('a device that joined again counts as a leaver and a joiner', () {
      final plan = MatrixRtcMediaKeys.plan(
        sharedWith: {alice, bob},
        members: {alice, bobAgain},
        keyAge: const Duration(seconds: 1),
      );

      expect(plan.rotates, isTrue);
      expect(plan.recipients, {alice, bobAgain});
    });

    test('nothing changed, nothing is sent', () {
      final plan = MatrixRtcMediaKeys.plan(
        sharedWith: {alice},
        members: {alice},
        keyAge: const Duration(minutes: 5),
      );

      expect(plan.recipients, isEmpty);
    });
  });

  group('parseKey', () {
    ToDeviceEvent keyEvent({
      Map<String, Object?>? keys,
      Map<String, Object?>? member,
      bool isEncrypted = true,
    }) => ToDeviceEvent(
      sender: '@bob:hs',
      type: MatrixRtcMediaKeys.eventType,
      content: {
        'keys': keys ?? {'index': 2, 'key': 'AQID'},
        'room_id': '!room',
        'member': member ?? {'claimed_device_id': 'B', 'id': '@bob:hs:B'},
      },
      encryptedContent: isEncrypted
          ? {'algorithm': 'm.olm.v1', 'sender_key': 'curve-B'}
          : null,
    );

    test('parseKey_always_readsTheKeyOfTheSendingDevice', () {
      // Act
      final key = MatrixRtcMediaKeys.parseKey(keyEvent(), '!room');

      // Assert
      expect(key?.userId, '@bob:hs');
      expect(key?.deviceId, 'B');
      expect(key?.index, 2);
      expect(key?.key, [1, 2, 3]);
    });

    test('parseKey_withTheMemberIdOfAnotherUser_keepsTheSender', () {
      // Act
      final key = MatrixRtcMediaKeys.parseKey(
        keyEvent(member: {'claimed_device_id': 'B', 'id': '@alice:hs:A'}),
        '!room',
      );

      // Assert
      expect(key?.userId, '@bob:hs');
      expect(key?.deviceId, 'B');
    });

    test('parseKey_inTheClear_isIgnored', () {
      // Act & Assert
      expect(
        MatrixRtcMediaKeys.parseKey(keyEvent(isEncrypted: false), '!room'),
        isNull,
      );
    });

    test('parseKey_withoutTheOlmSenderKey_isIgnored', () {
      // Arrange
      final event = ToDeviceEvent(
        sender: '@bob:hs',
        type: MatrixRtcMediaKeys.eventType,
        content: keyEvent().content,
        encryptedContent: {'algorithm': 'm.olm.v1'},
      );

      // Act & Assert
      expect(MatrixRtcMediaKeys.parseKey(event, '!room'), isNull);
    });

    test('parseKey_ofAnotherRoom_isIgnored', () {
      // Act & Assert
      expect(MatrixRtcMediaKeys.parseKey(keyEvent(), '!other'), isNull);
    });

    test('parseKey_withAMalformedKey_isIgnored', () {
      // Act & Assert
      for (final key in ['not base64!', '']) {
        expect(
          MatrixRtcMediaKeys.parseKey(
            keyEvent(keys: {'index': 0, 'key': key}),
            '!room',
          ),
          isNull,
        );
      }
    });

    test('parseKey_withAnIndexOutOfTheKeyring_isIgnored', () {
      // Act & Assert
      for (final index in [-1, 256]) {
        expect(
          MatrixRtcMediaKeys.parseKey(
            keyEvent(keys: {'index': index, 'key': 'AQ'}),
            '!room',
          ),
          isNull,
        );
      }
    });
  });

  group('run', () {
    late _FakeClient client;
    late List<CallMediaKey> keys;
    late StreamSubscription<CallMediaKey> subscription;
    late DateTime time;

    void start(FakeAsync async) {
      keys = [];
      subscription = MatrixRtcMediaKeys(
        client,
        '!room',
        _memberType,
        now: () => time,
      ).run().listen(keys.add);
      async.flushMicrotasks();
    }

    setUp(() {
      time = DateTime.now();
      client = _FakeClient()..join('@me:hs', 'ME');
    });

    test('run_beforeTheOwnMembership_sendsNoKey', () {
      fakeAsync((async) {
        // Arrange
        client = _FakeClient()..addDevice('@bob:hs', 'B');
        start(async);
        client.join('@bob:hs', 'B');
        async.flushMicrotasks();
        final beforeTheOwnMembership = [...client.sent];

        // Act
        client.join('@me:hs', 'ME');
        async.flushMicrotasks();

        // Assert
        expect(beforeTheOwnMembership, isEmpty);
        expect(client.sent, ['B@0']);
      });
    });

    test('run_withAKeyOverAnotherDeviceSession_ignoresIt', () {
      fakeAsync((async) {
        // Arrange
        client
          ..addDevice('@bob:hs', 'B')
          ..addDevice('@bob:hs', 'B2')
          ..join('@bob:hs', 'B');
        start(async);

        // Act
        client.sendKey(sender: '@bob:hs', deviceId: 'B', senderDevice: 'B2');
        async.flushMicrotasks();

        // Assert
        expect(keys, hasLength(1));
      });
    });

    test('run_whenARotationFailsToSend_retriesItAsARotation', () {
      fakeAsync((async) {
        // Arrange
        client
          ..addDevice('@bob:hs', 'B')
          ..addDevice('@carol:hs', 'C')
          ..join('@bob:hs', 'B');
        start(async);
        time = time.add(const Duration(seconds: 11));
        client.failingSends = 1;

        // Act
        client.join('@carol:hs', 'C');
        async.flushMicrotasks();
        async.elapse(MatrixRtcMediaKeys.retryDelay);
        async.elapse(MatrixRtcMediaKeys.useKeyDelay);

        // Assert
        expect(client.sent, ['B@0', 'B@2', 'C@2']);
        expect(keys.last.index, 2);
      });
    });

    test('run_always_startsWithTheOwnKey', () {
      fakeAsync((async) {
        // Act
        start(async);

        // Assert
        expect(keys.single.participantId, '@me:hs:ME');
        expect(keys.single.index, 0);
        expect(keys.single.key, hasLength(16));
      });
    });

    test('run_whenAMemberJoins_sendsItTheCurrentKey', () {
      fakeAsync((async) {
        // Arrange
        start(async);
        client.addDevice('@bob:hs', 'B');

        // Act
        client.join('@bob:hs', 'B');
        async.flushMicrotasks();

        // Assert
        expect(client.sent, ['B@0']);
      });
    });

    test('run_withAKeyOfACallMember_appliesItToThatDevice', () {
      fakeAsync((async) {
        // Arrange
        client.addDevice('@bob:hs', 'B');
        client.join('@bob:hs', 'B');
        start(async);

        // Act
        client.sendKey(sender: '@bob:hs', deviceId: 'B', memberId: '@x:hs:X');
        async.flushMicrotasks();

        // Assert
        expect(keys.last.participantId, '@bob:hs:B');
        expect(keys.last.index, 3);
      });
    });

    test('run_withAKeyClaimingTheOwnDevice_ignoresIt', () {
      fakeAsync((async) {
        // Arrange
        start(async);

        // Act
        client.sendKey(sender: '@me:hs', deviceId: 'ME', memberId: '@me:hs:ME');
        async.flushMicrotasks();

        // Assert
        expect(keys, hasLength(1));
        expect(keys.single.index, 0);
      });
    });

    test('run_withAKeyBeforeItsMembership_appliesItOnceTheDeviceJoins', () {
      fakeAsync((async) {
        // Arrange
        client.addDevice('@bob:hs', 'B');
        start(async);
        client.sendKey(sender: '@bob:hs', deviceId: 'B');
        async.flushMicrotasks();
        final beforeTheMembership = keys.length;

        // Act
        client.join('@bob:hs', 'B');
        async.flushMicrotasks();

        // Assert
        expect(beforeTheMembership, 1);
        expect(keys.last.participantId, '@bob:hs:B');
      });
    });

    test('run_whenTheLastOtherDeviceLeaves_rotatesTheOwnKey', () {
      fakeAsync((async) {
        // Arrange
        client.addDevice('@bob:hs', 'B');
        client.join('@bob:hs', 'B');
        start(async);

        // Act
        client.leave('@bob:hs', 'B');
        async.flushMicrotasks();

        // Assert
        expect(keys.map((key) => key.index), [0, 1]);
        expect(keys.last.key, isNot(keys.first.key));
      });
    });

    test('run_whenADeviceLeaves_usesTheNewKeyOnceTheOthersHadTime', () {
      fakeAsync((async) {
        // Arrange
        client
          ..addDevice('@bob:hs', 'B')
          ..addDevice('@carol:hs', 'C')
          ..join('@bob:hs', 'B')
          ..join('@carol:hs', 'C');
        start(async);

        // Act
        client.leave('@bob:hs', 'B');
        async.flushMicrotasks();
        final beforeTheDelay = keys.length;
        async.elapse(MatrixRtcMediaKeys.useKeyDelay);

        // Assert
        expect(client.sent.last, 'C@1');
        expect(beforeTheDelay, 1);
        expect(keys.last.index, 1);
      });
    });

    test('run_whenStoppedDuringTheDelay_keepsTheNewKeyUnused', () {
      fakeAsync((async) {
        // Arrange
        client
          ..addDevice('@bob:hs', 'B')
          ..addDevice('@carol:hs', 'C')
          ..join('@bob:hs', 'B')
          ..join('@carol:hs', 'C');
        start(async);
        client.leave('@bob:hs', 'B');
        async.flushMicrotasks();

        // Act
        subscription.cancel();
        async.elapse(MatrixRtcMediaKeys.useKeyDelay);

        // Assert
        expect(keys.map((key) => key.index), [0]);
      });
    });

    test('run_whenTheSendFails_retriesIt', () {
      fakeAsync((async) {
        // Arrange
        client
          ..addDevice('@bob:hs', 'B')
          ..failingSends = 1;
        start(async);

        // Act
        client.join('@bob:hs', 'B');
        async.flushMicrotasks();
        final beforeTheRetry = [...client.sent];
        async.elapse(MatrixRtcMediaKeys.retryDelay);

        // Assert
        expect(beforeTheRetry, isEmpty);
        expect(client.sent, ['B@0']);
      });
    });

    test('run_withANewDeviceOfAKnownUser_refreshesItsKeysFirst', () {
      fakeAsync((async) {
        // Arrange
        client
          ..addDevice('@bob:hs', 'B')
          ..addDevice('@bob:hs', 'B2', afterRefresh: true);
        start(async);

        // Act
        client.join('@bob:hs', 'B2');
        async.flushMicrotasks();

        // Assert
        expect(client.refreshed, [
          {'@bob:hs'},
        ]);
        expect(client.sent, ['B2@0']);
      });
    });

    test('run_withADeviceWhoseKeysStayUnknown_sendsToItOnARetry', () {
      fakeAsync((async) {
        // Arrange
        start(async);
        client.join('@bob:hs', 'B');
        async.flushMicrotasks();
        final beforeItsKeys = [...client.sent];

        // Act
        client.addDevice('@bob:hs', 'B');
        async.elapse(MatrixRtcMediaKeys.retryDelay);

        // Assert
        expect(beforeItsKeys, isEmpty);
        expect(client.sent, ['B@0']);
      });
    });

    test('run_whenAMembershipExpires_rotatesTheOwnKey', () async {
      // Arrange
      client
        ..addDevice('@bob:hs', 'B')
        ..join('@bob:hs', 'B', expires: 200);
      final keys = <CallMediaKey>[];
      final subscription = MatrixRtcMediaKeys(
        client,
        '!room',
        _memberType,
      ).run().listen(keys.add);

      // Act
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await subscription.cancel();

      // Assert
      expect(keys.map((key) => key.index), [0, 1]);
    });
  });
}

const _memberType = 'org.matrix.msc3401.call.member';

class _FakeRoom extends Fake implements Room {
  @override
  Map<String, Map<String, StrippedStateEvent>> states = {};

  @override
  Future<void> postLoad() async {}
}

class _FakeDeviceKeys extends Fake implements DeviceKeys {
  _FakeDeviceKeys(this.deviceId);

  @override
  final String deviceId;

  @override
  String get curve25519Key => 'curve-$deviceId';
}

class _FakeDeviceKeysList extends Fake implements DeviceKeysList {
  @override
  Map<String, DeviceKeys> deviceKeys = {};
}

class _FakeClient extends Fake implements Client {
  final _room = _FakeRoom();
  final _afterRefresh = <(String, String)>[];
  final refreshed = <Set<String>>[];
  final sent = <String>[];
  var failingSends = 0;

  @override
  String? get userID => '@me:hs';

  @override
  String? get deviceID => 'ME';

  @override
  Room? getRoomById(String id) => id == '!room' ? _room : null;

  @override
  final CachedStreamController<ToDeviceEvent> onToDeviceEvent =
      CachedStreamController();

  @override
  final CachedStreamController<({String roomId, StrippedStateEvent state})>
  onRoomState = CachedStreamController();

  @override
  final Map<String, DeviceKeysList> userDeviceKeys = {};

  @override
  Future<void> updateUserDeviceKeys({Set<String>? additionalUsers}) async {
    refreshed.add(additionalUsers ?? {});
    for (final (userId, deviceId) in _afterRefresh) {
      _addDeviceKeys(userId, deviceId);
    }
    _afterRefresh.clear();
  }

  @override
  Future<void> sendToDeviceEncrypted(
    List<DeviceKeys> deviceKeys,
    String eventType,
    Map<String, dynamic> message, {
    String? messageId,
    bool onlyVerified = false,
  }) async {
    if (failingSends > 0) {
      failingSends--;
      throw Exception('offline');
    }
    final index = (message['keys'] as Map)['index'];
    for (final device in deviceKeys) {
      sent.add('${device.deviceId}@$index');
    }
  }

  void addDevice(String userId, String deviceId, {bool afterRefresh = false}) {
    if (afterRefresh) {
      _afterRefresh.add((userId, deviceId));
    } else {
      _addDeviceKeys(userId, deviceId);
    }
  }

  void _addDeviceKeys(String userId, String deviceId) =>
      (userDeviceKeys[userId] ??= _FakeDeviceKeysList()).deviceKeys[deviceId] =
          _FakeDeviceKeys(deviceId);

  void join(String userId, String deviceId, {int expires = 14400000}) =>
      _setMember(userId, deviceId, {
        'application': 'm.call',
        'call_id': '',
        'device_id': deviceId,
        'created_ts': DateTime.now().millisecondsSinceEpoch,
        'expires': expires,
      });

  void leave(String userId, String deviceId) =>
      _setMember(userId, deviceId, {});

  void _setMember(
    String userId,
    String deviceId,
    Map<String, Object?> content,
  ) {
    final event = StrippedStateEvent(
      type: _memberType,
      content: content,
      senderId: userId,
      stateKey: '_${userId}_${deviceId}_m.call',
    );
    (_room.states[_memberType] ??= {})[event.stateKey!] = event;
    onRoomState.add((roomId: '!room', state: event));
  }

  void sendKey({
    required String sender,
    required String deviceId,
    String? memberId,
    String? senderDevice,
  }) => onToDeviceEvent.add(
    ToDeviceEvent(
      sender: sender,
      type: MatrixRtcMediaKeys.eventType,
      content: {
        'keys': {'index': 3, 'key': 'AQID'},
        'room_id': '!room',
        'member': {'claimed_device_id': deviceId, 'id': ?memberId},
      },
      encryptedContent: {
        'algorithm': 'm.olm.v1',
        'sender_key': 'curve-${senderDevice ?? deviceId}',
      },
    ),
  );
}
