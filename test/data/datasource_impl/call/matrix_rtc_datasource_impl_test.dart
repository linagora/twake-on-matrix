import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource_impl/call/matrix_rtc_datasource_impl.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';

class _FakeRoom extends Fake implements Room {
  @override
  Membership get membership => Membership.join;

  @override
  String? get roomVersion => '10';

  @override
  bool canChangeStateEvent(String action) => true;
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
    if (body.isNotEmpty && failingMemberships > 0) {
      failingMemberships--;
      writes.add('membership failed');
      throw Exception('offline');
    }
    writes.add(body.isEmpty ? 'left' : 'membership');
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
      async.elapse(const Duration(seconds: 20));

      expect(client.delayedActions.last, 'send delay-2');
      expect(client.delayedActions.length, actions);
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
}
