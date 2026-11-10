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

class _FakeRoom extends Fake implements Room {
  var canJoin = true;

  @override
  String get id => '!room:hs.test';

  @override
  bool get encrypted => false;

  @override
  bool get isDirectChat => false;

  @override
  Membership get membership => Membership.join;

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
  final tokenRequests = <Map<String, Object?>>[];

  @override
  final CachedStreamController<Event> onTimelineEvent =
      CachedStreamController();

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
    if (request.url.path.endsWith('/sfu/get')) {
      tokenRequests.add(jsonDecode(request.body) as Map<String, Object?>);
      return http.Response('{"url":"wss://lk.test","jwt":"jwt"}', 200);
    }
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
    writes.add(body.isEmpty ? 'left' : 'membership');
    timeline.add(body.isEmpty ? 'left' : 'membership');
    return r'$event';
  }
}

void main() {
  test('a membership the homeserver ended during a pause is sent again', () {
    fakeAsync((async) {
      final client = _FakeClient();
      final datasource = MatrixRtcDatasourceImpl(client);

      datasource.joinMembership(
        roomId: '!room:hs.test',
        serviceUrl: 'https://rtc.test',
        isVideo: false,
      );
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 6));

      expect(client.writes, [
        'delayed leave',
        'membership',
        'delayed leave',
        'membership',
      ]);
      async.elapse(const Duration(seconds: 5));
      expect(client.delayedActions.last, 'restart delay-2');
      datasource.dispose();
    });
  });

  test('extend_whenTheExtensionFails_triesAgainSoon', () {
    fakeAsync((async) {
      final client = _FakeClient();
      final datasource = MatrixRtcDatasourceImpl(client);
      datasource.joinMembership(
        roomId: '!room:hs.test',
        serviceUrl: 'https://rtc.test',
        isVideo: false,
      );
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 6));
      client
        ..writes.clear()
        ..failingMemberships = 1;

      async.elapse(const Duration(hours: 4) - const Duration(minutes: 1));
      async.elapse(const Duration(seconds: 30));

      expect(client.writes, ['membership failed', 'membership']);
      datasource.dispose();
    });
  });

  test('leaveMembership_whenTheRoomIsGone_stopsRenewingTheMembership', () {
    fakeAsync((async) {
      final client = _FakeClient();
      final datasource = MatrixRtcDatasourceImpl(client);
      datasource.joinMembership(
        roomId: '!room:hs.test',
        serviceUrl: 'https://rtc.test',
        isVideo: false,
      );
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 6));
      client.isRoomGone = true;

      datasource.leaveMembership('!room:hs.test').ignore();
      async.flushMicrotasks();
      final actions = client.delayedActions.length;
      final writes = client.writes.length;
      async.elapse(const Duration(hours: 5));

      expect(client.delayedActions.last, 'send delay-2');
      expect(client.delayedActions.length, actions);
      expect(client.writes.length, writes);
      datasource.dispose();
    });
  });

  test('leaveMembership_whileAnExtensionIsSent_leavesAfterIt', () {
    fakeAsync((async) {
      final client = _FakeClient();
      final datasource = MatrixRtcDatasourceImpl(client);
      datasource.joinMembership(
        roomId: '!room:hs.test',
        serviceUrl: 'https://rtc.test',
        isVideo: false,
      );
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 6));
      final hold = client.holdMemberships = Completer<void>();
      async.elapse(const Duration(hours: 4) - const Duration(minutes: 1));

      datasource.leaveMembership('!room:hs.test').ignore();
      async.flushMicrotasks();
      expect(client.delayedActions, isNot(contains('send delay-2')));
      hold.complete();
      async.flushMicrotasks();

      expect(client.writes.last, 'membership');
      expect(client.delayedActions.last, 'send delay-2');
      datasource.dispose();
    });
  });

  test('leaveMembership_whileAnExtensionRetryWaits_writesNoMembership', () {
    fakeAsync((async) {
      final client = _FakeClient();
      final datasource = MatrixRtcDatasourceImpl(client);
      datasource.joinMembership(
        roomId: '!room:hs.test',
        serviceUrl: 'https://rtc.test',
        isVideo: false,
      );
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 6));
      client.failingMemberships = 1;
      async.elapse(const Duration(hours: 4) - const Duration(minutes: 1));
      expect(client.writes.last, 'membership failed');

      datasource.leaveMembership('!room:hs.test').ignore();
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 1));

      expect(client.writes.last, 'membership failed');
      datasource.dispose();
    });
  });

  group('stateKeyFor', () {
    test('prefixes the key with an underscore in a usual room', () {
      expect(
        MatrixRtcDatasourceImpl.stateKeyFor(
          userId: '@alice:localhost',
          deviceId: 'DEV',
          roomVersion: '10',
        ),
        '_@alice:localhost_DEV_m.call',
      );
    });

    test('does not on the room versions of MSC3757 and MSC3779', () {
      for (final version in [
        'org.matrix.msc3757.11',
        'org.matrix.msc3779.10',
      ]) {
        expect(
          MatrixRtcDatasourceImpl.stateKeyFor(
            userId: '@alice:localhost',
            deviceId: 'DEV',
            roomVersion: version,
          ),
          '@alice:localhost_DEV_m.call',
        );
      }
    });
  });

  test('the membership is an MSC4143 session membership', () {
    expect(
      MatrixRtcDatasourceImpl.membershipContent(
        userId: '@alice:localhost',
        deviceId: 'DEV',
        serviceUrl: 'http://127.0.0.1:3003',
        isVideo: true,
      ),
      {
        'application': 'm.call',
        'call_id': '',
        'scope': 'm.room',
        'device_id': 'DEV',
        'membershipID': '@alice:localhost:DEV',
        'expires': 14400000,
        'm.call.intent': 'video',
        'focus_active': {
          'type': 'livekit',
          'focus_selection': 'oldest_membership',
        },
        'foci_preferred': [
          {'type': 'livekit', 'livekit_service_url': 'http://127.0.0.1:3003'},
        ],
      },
    );
  });

  test('an extended membership keeps its created_ts and grows expires', () {
    final content = MatrixRtcDatasourceImpl.membershipContent(
      userId: '@alice:localhost',
      deviceId: 'DEV',
      serviceUrl: 'http://127.0.0.1:3003',
      isVideo: false,
      expiries: 2,
      createdTs: 1700000000000,
    );

    expect(content['expires'], 28800000);
    expect(content['created_ts'], 1700000000000);
  });

  group('parseServer', () {
    test('reads the LiveKit url and token', () {
      expect(
        MatrixRtcDatasourceImpl.parseServer(
          200,
          '{"url":"ws://127.0.0.1:7880","jwt":"token"}',
        ),
        const CallServer(url: 'ws://127.0.0.1:7880', token: 'token'),
      );
    });

    test('an error status is a token failure', () {
      expect(
        () => MatrixRtcDatasourceImpl.parseServer(403, '{}'),
        throwsA(isA<CallTokenFailedException>()),
      );
    });

    test('a body without url or jwt is a token failure', () {
      expect(
        () => MatrixRtcDatasourceImpl.parseServer(200, '{"url":"ws://x"}'),
        throwsA(isA<CallTokenFailedException>()),
      );
    });
  });

  test('leaveMembership_whileAMembershipIsSentAgain_leavesAfterIt', () {
    fakeAsync((async) {
      final client = _FakeClient();
      final datasource = MatrixRtcDatasourceImpl(client);
      datasource.joinMembership(
        roomId: '!room:hs.test',
        serviceUrl: 'https://rtc.test',
        isVideo: false,
      );
      async.flushMicrotasks();
      final hold = client.holdMemberships = Completer<void>();
      async.elapse(const Duration(seconds: 6));

      datasource.leaveMembership('!room:hs.test').ignore();
      async.flushMicrotasks();
      expect(client.timeline, isNot(contains('send delay-2')));
      hold.complete();
      async.flushMicrotasks();

      expect(
        client.timeline,
        containsAllInOrder(['restart delay-1', 'membership', 'send delay-2']),
      );
      expect(client.timeline.last, 'send delay-2');
      datasource.dispose();
    });
  });

  test('getRoomInfo_withoutTheRightToTheCallEvent_cannotJoin', () {
    final client = _FakeClient().._room.canJoin = false;

    expect(
      MatrixRtcDatasourceImpl(client).getRoomInfo('!room:hs.test').canJoin,
      isFalse,
    );
  });

  test('fetchServer_always_sendsTheOpenIdTokenOfThisDevice', () async {
    final client = _FakeClient();

    final server = await MatrixRtcDatasourceImpl(
      client,
    ).fetchServer(roomId: '!room:hs.test', serviceUrl: 'https://rtc.test');

    expect(server, const CallServer(url: 'wss://lk.test', token: 'jwt'));
    expect(client.tokenRequests.single, {
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

  test('watchRoomEncrypted_whenEncryptionIsTurnedOn_emits', () async {
    final client = _FakeClient();
    final encrypted = <void>[];
    MatrixRtcDatasourceImpl(
      client,
    ).watchRoomEncrypted('!room:hs.test').listen(encrypted.add);

    client.onTimelineEvent.add(
      Event(
        content: {'algorithm': 'm.megolm.v1.aes-sha2'},
        type: EventTypes.Encryption,
        eventId: r'$encryption',
        senderId: '@alice:hs.test',
        originServerTs: DateTime.now(),
        stateKey: '',
        room: client._room,
      ),
    );
    await pumpEventQueue();

    expect(encrypted, hasLength(1));
  });
}
