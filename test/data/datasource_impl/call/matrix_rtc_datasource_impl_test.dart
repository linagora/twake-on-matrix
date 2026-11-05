import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports, the SDK does not export the type of its streams.
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:twake_chat/data/datasource_impl/call/matrix_rtc_datasource_impl.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';

const _room = CallRoom('!room:hs.test');
const _join = CallJoin(room: _room, serviceUrl: 'https://rtc.test');
const _alice = CallDevice(userId: '@alice:localhost', deviceId: 'DEV');

class _FakeRoom extends Fake implements Room {
  var canJoin = true;

  @override
  String get id => '!room:hs.test';

  var isEncrypted = false;

  @override
  bool get encrypted => isEncrypted;

  @override
  bool get isDirectChat => false;

  var currentMembership = Membership.join;

  @override
  Membership get membership => currentMembership;

  @override
  String? get roomVersion => '10';

  @override
  bool canChangeStateEvent(String action) => canJoin;
}

/// Records the membership writes; the first restart finds the delayed leave
/// already sent, as after a pause of the app.
class _FakeClient extends Fake implements Client {
  final writes = <String>[];
  final delayedActions = <String>[];
  final _room = _FakeRoom();
  var _isLapsed = true;
  var _delays = 0;
  var isRoomGone = false;
  var failingMemberships = 0;
  Completer<void>? holdMemberships;
  final timeline = <String>[];
  Map<String, Object?>? lastMembership;
  static final serverTime = DateTime.utc(2026, 11, 12, 9);

  @override
  final CachedStreamController<SyncUpdate> onSync = CachedStreamController();

  @override
  Future<OpenIdCredentials> requestOpenIdToken(
    String userId,
    Map<String, Object?> body,
  ) async => OpenIdCredentials(
    accessToken: 'openid',
    expiresIn: 3600,
    matrixServerName: 'hs.test',
    tokenType: 'Bearer',
  );

  @override
  String? get userID => '@bob:hs.test';

  @override
  String? get deviceID => 'BOB';

  @override
  Uri? get baseUri => Uri.parse('https://hs.test');

  @override
  String? get bearerToken => 'token';

  @override
  Room? getRoomById(String id) => isRoomGone ? null : _room;

  @override
  late final http.Client httpClient = MockClient((request) async {
    if (request.url.path.contains('delayed_events')) {
      final action = jsonDecode(request.body)['action'];
      delayedActions.add('$action ${request.url.pathSegments.last}');
      timeline.add('$action ${request.url.pathSegments.last}');
      if (!_isLapsed) return http.Response('{}', 200);
      _isLapsed = false;
      return http.Response('{"errcode":"M_NOT_FOUND","error":"gone"}', 404);
    }
    writes.add('delayed leave');
    return http.Response('{"delay_id":"delay-${++_delays}"}', 200);
  });

  @override
  Never unexpectedResponse(http.BaseResponse response, Uint8List body) =>
      throw MatrixException.fromJson(jsonDecode(utf8.decode(body)));

  @override
  Future<String> setRoomStateWithKey(
    String roomId,
    String eventType,
    String stateKey,
    Map<String, Object?> body,
  ) async {
    if (body.isNotEmpty) await holdMemberships?.future;
    if (body.isNotEmpty && failingMemberships > 0) {
      failingMemberships--;
      writes.add('membership failed');
      throw Exception('offline');
    }
    if (body.isNotEmpty) lastMembership = body;
    writes.add(body.isEmpty ? 'left' : 'membership');
    timeline.add(body.isEmpty ? 'left' : 'membership');
    return r'$event';
  }

  @override
  Future<MatrixEvent> getOneRoomEvent(String roomId, String eventId) async =>
      MatrixEvent(
        type: eventId,
        content: {},
        senderId: '@bob:hs.test',
        eventId: eventId,
        originServerTs: serverTime,
      );
}

void main() {
  test('restart_afterThePauseEndedTheMembership_sendsItAgain', () {
    fakeAsync((async) {
      // Arrange
      final client = _FakeClient();
      final datasource = MatrixRtcDatasourceImpl(client);
      datasource.joinMembership(_join);
      async.flushMicrotasks();

      // Act
      async.elapse(const Duration(seconds: 6));
      final writes = [...client.writes];
      async.elapse(const Duration(seconds: 5));

      // Assert
      expect(writes, [
        'delayed leave',
        'membership',
        'delayed leave',
        'membership',
      ]);
      expect(client.delayedActions.last, 'restart delay-2');
      datasource.dispose();
    });
  });

  test('extend_whenTheExtensionFails_triesAgainSoon', () {
    fakeAsync((async) {
      // Arrange
      final client = _FakeClient();
      final datasource = MatrixRtcDatasourceImpl(client);
      datasource.joinMembership(_join);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 6));
      client
        ..writes.clear()
        ..failingMemberships = 1;

      // Act
      async.elapse(const Duration(hours: 4) - const Duration(minutes: 1));
      async.elapse(const Duration(seconds: 30));

      // Assert
      expect(client.writes, ['membership failed', 'membership']);
      datasource.dispose();
    });
  });

  test('extend_always_countsFromTheServerTimeOfTheFirstMembership', () {
    fakeAsync((async) {
      // Arrange
      final client = _FakeClient();
      final datasource = MatrixRtcDatasourceImpl(client);
      datasource.joinMembership(_join);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 6));

      // Act
      async.elapse(const Duration(hours: 4) - const Duration(minutes: 1));

      // Assert
      expect(client.lastMembership, containsPair('expires', 8 * 3600 * 1000));
      expect(
        client.lastMembership,
        containsPair(
          'created_ts',
          _FakeClient.serverTime.millisecondsSinceEpoch,
        ),
      );
      datasource.dispose();
    });
  });

  test('leaveMembership_whenTheRoomIsGone_stopsRenewingTheMembership', () {
    fakeAsync((async) {
      // Arrange
      final client = _FakeClient();
      final datasource = MatrixRtcDatasourceImpl(client);
      datasource.joinMembership(_join);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 6));
      client.isRoomGone = true;

      // Act
      datasource.leaveMembership(_room).ignore();
      async.flushMicrotasks();
      final actions = client.delayedActions.length;
      final writes = client.writes.length;
      async.elapse(const Duration(hours: 5));

      // Assert
      expect(client.delayedActions.last, 'send delay-2');
      expect(client.delayedActions.length, actions);
      expect(client.writes.length, writes);
      datasource.dispose();
    });
  });

  test('leaveMembership_whileAnExtensionIsSent_leavesAfterIt', () {
    fakeAsync((async) {
      // Arrange
      final client = _FakeClient();
      final datasource = MatrixRtcDatasourceImpl(client);
      datasource.joinMembership(_join);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 6));
      final hold = client.holdMemberships = Completer<void>();
      async.elapse(const Duration(hours: 4) - const Duration(minutes: 1));

      // Act
      datasource.leaveMembership(_room).ignore();
      async.flushMicrotasks();
      final actionsDuringTheExtension = [...client.delayedActions];
      hold.complete();
      async.flushMicrotasks();

      // Assert
      expect(actionsDuringTheExtension, isNot(contains('send delay-2')));
      expect(client.writes.last, 'membership');
      expect(client.delayedActions.last, 'send delay-2');
      datasource.dispose();
    });
  });

  test('leaveMembership_whileAnExtensionRetryWaits_writesNoMembership', () {
    fakeAsync((async) {
      // Arrange
      final client = _FakeClient();
      final datasource = MatrixRtcDatasourceImpl(client);
      datasource.joinMembership(_join);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 6));
      client.failingMemberships = 1;
      async.elapse(const Duration(hours: 4) - const Duration(minutes: 1));

      // Act
      datasource.leaveMembership(_room).ignore();
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 1));

      // Assert
      expect(client.writes.last, 'membership failed');
      datasource.dispose();
    });
  });

  test('stateKeyFor_inAUsualRoom_isPrefixedWithAnUnderscore', () {
    // Act
    final stateKey = MatrixRtcDatasourceImpl.stateKeyFor(
      _alice,
      roomVersion: '10',
    );

    // Assert
    expect(stateKey, '_@alice:localhost_DEV_m.call');
  });

  test('stateKeyFor_onTheRoomVersionsOfMsc3757AndMsc3779_isNotPrefixed', () {
    for (final version in ['org.matrix.msc3757.11', 'org.matrix.msc3779.10']) {
      // Act
      final stateKey = MatrixRtcDatasourceImpl.stateKeyFor(
        _alice,
        roomVersion: version,
      );

      // Assert
      expect(stateKey, '@alice:localhost_DEV_m.call');
    }
  });

  test('leaveMembership_whileAMembershipIsSentAgain_leavesAfterIt', () {
    fakeAsync((async) {
      // Arrange
      final client = _FakeClient();
      final datasource = MatrixRtcDatasourceImpl(client);
      datasource.joinMembership(_join);
      async.flushMicrotasks();
      final hold = client.holdMemberships = Completer<void>();
      async.elapse(const Duration(seconds: 6));

      // Act
      datasource.leaveMembership(_room).ignore();
      async.flushMicrotasks();
      final timelineDuringTheResend = [...client.timeline];
      hold.complete();
      async.flushMicrotasks();

      // Assert
      expect(timelineDuringTheResend, isNot(contains('send delay-2')));
      expect(
        client.timeline,
        containsAllInOrder(['restart delay-1', 'membership', 'send delay-2']),
      );
      expect(client.timeline.last, 'send delay-2');
      datasource.dispose();
    });
  });

  test('getRoomInfo_withoutTheRightToTheCallEvent_cannotJoin', () {
    // Arrange
    final client = _FakeClient().._room.canJoin = false;

    // Act
    final info = MatrixRtcDatasourceImpl(client).getRoomInfo(_room);

    // Assert
    expect(info.canJoin, isFalse);
  });

  test('createTokenRequest_always_carriesTheOpenIdTokenOfThisDevice', () async {
    // Arrange
    final client = _FakeClient();

    // Act
    final request = await MatrixRtcDatasourceImpl(
      client,
    ).createTokenRequest(_room);

    // Assert
    expect(request.toJson(), {
      'room': '!room:hs.test',
      'openid_token': {
        'access_token': 'openid',
        'expires_in': 3600,
        'matrix_server_name': 'hs.test',
        'token_type': 'Bearer',
      },
      'device_id': 'BOB',
    });
  });

  test('watchRoomEncrypted_whenASyncEncryptsTheRoom_emitsOnce', () async {
    // Arrange
    final client = _FakeClient();
    final encrypted = <void>[];
    MatrixRtcDatasourceImpl(
      client,
    ).watchRoomEncrypted(_room).listen(encrypted.add);
    await pumpEventQueue();

    // Act
    client.onSync.add(SyncUpdate(nextBatch: 'clear'));
    await pumpEventQueue();
    final afterAClearSync = encrypted.length;
    client._room.isEncrypted = true;
    client.onSync
      ..add(SyncUpdate(nextBatch: 'limited'))
      ..add(SyncUpdate(nextBatch: 'next'));
    await pumpEventQueue();

    // Assert
    expect(afterAClearSync, 0);
    expect(encrypted, hasLength(1));
  });

  test('watchRoomEncrypted_whenEncryptedBeforeItListens_emitsAtOnce', () async {
    // Arrange
    final client = _FakeClient().._room.isEncrypted = true;
    final encrypted = <void>[];

    // Act
    MatrixRtcDatasourceImpl(
      client,
    ).watchRoomEncrypted(_room).listen(encrypted.add);
    await pumpEventQueue();

    // Assert
    expect(encrypted, hasLength(1));
  });

  test(
    'watchRoomEncrypted_whenRemovedFromAnEncryptedRoom_emitsOnceThenFails',
    () async {
      // Arrange
      final client = _FakeClient().._room.isEncrypted = true;
      final encrypted = <void>[];
      final errors = <Object>[];
      MatrixRtcDatasourceImpl(
        client,
      ).watchRoomEncrypted(_room).listen(encrypted.add, onError: errors.add);
      await pumpEventQueue();

      // Act
      client.onSync.add(SyncUpdate(nextBatch: 'still'));
      await pumpEventQueue();
      client._room.currentMembership = Membership.leave;
      client.onSync.add(SyncUpdate(nextBatch: 'kicked'));
      await pumpEventQueue();

      // Assert
      expect(encrypted, hasLength(1));
      expect(errors.single, isA<CallRoomNotFoundException>());
    },
  );

  test('watchRoomEncrypted_whenTheRoomIsGone_failsAsRoomNotFound', () async {
    // Arrange
    final client = _FakeClient()..isRoomGone = true;

    // Act & Assert
    await expectLater(
      MatrixRtcDatasourceImpl(client).watchRoomEncrypted(_room),
      emitsError(isA<CallRoomNotFoundException>()),
    );
  });

  test(
    'watchRoomEncrypted_whenRemovedFromTheRoom_failsAsRoomNotFound',
    () async {
      // Arrange
      final client = _FakeClient();
      final errors = <Object>[];
      MatrixRtcDatasourceImpl(
        client,
      ).watchRoomEncrypted(_room).listen((_) {}, onError: errors.add);
      await pumpEventQueue();

      // Act
      client._room.currentMembership = Membership.leave;
      client.onSync.add(SyncUpdate(nextBatch: 'kicked'));
      await pumpEventQueue();

      // Assert
      expect(errors.single, isA<CallRoomNotFoundException>());
    },
  );
}
