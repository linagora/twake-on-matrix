import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/datasource/call/call_media_datasource.dart';
import 'package:twake_chat/data/datasource/call/call_token_datasource.dart';
import 'package:twake_chat/data/datasource/call/matrix_rtc_datasource.dart';
import 'package:twake_chat/data/model/call/sfu_token_request.dart';
import 'package:twake_chat/data/repository/call/call_repository_impl.dart';
import 'package:twake_chat/domain/model/call/call_media_key.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';

const _server = CallServer(url: 'wss://lk.test', token: 'jwt');
const _room = CallRoom('!r');
const _join = CallJoin(room: _room, serviceUrl: 'https://rtc', isVideo: true);

class _FakeRtc implements MatrixRtcDatasource {
  final calls = <String>[];

  @override
  Stream<void> watchRoomEncrypted(CallRoom room) => const Stream.empty();

  @override
  CallRoomInfo getRoomInfo(CallRoom room) =>
      const CallRoomInfo(isEncrypted: false, isDirect: true, canJoin: true);

  @override
  ({String? displayName, Uri? avatarUrl}) getMemberProfile(
    CallRoom room,
    CallParticipant participant,
  ) => (
    displayName: '${participant.userId} in ${room.id}',
    avatarUrl: Uri.parse('mxc://a'),
  );

  @override
  Future<SfuTokenRequest> createTokenRequest(CallRoom room) async {
    calls.add('tokenRequest ${room.id}');
    return SfuTokenRequest(room: room.id, openidToken: {}, deviceId: 'BOB');
  }

  @override
  Future<void> endStaleOwnMembership(CallRoom room) async =>
      calls.add('endStale ${room.id}');

  @override
  Future<void> joinMembership(CallJoin join) async =>
      calls.add('join ${join.room.id} ${join.serviceUrl} ${join.isVideo}');

  @override
  Future<void> leaveMembership(CallRoom room) async =>
      calls.add('leave ${room.id}');

  final keys = StreamController<CallMediaKey>();

  @override
  Stream<CallMediaKey> watchMediaKeys(CallRoom room) {
    calls.add('keys ${room.id}');
    return keys.stream;
  }
}

class _FakeToken implements CallTokenDatasource {
  final calls = <String>[];

  @override
  Future<CallServer> fetchServer(
    String serviceUrl,
    SfuTokenRequest request,
  ) async {
    calls.add('fetch $serviceUrl ${request.room}');
    return _server;
  }
}

class _FakeMedia implements CallMediaDatasource {
  final calls = <String>[];
  var participants = const <CallParticipant>[];

  @override
  Future<void> connect(CallServer server, CallMediaState media) async =>
      calls.add(
        'connect ${server.url} ${media.isMicrophoneOn} ${media.isCameraOn} '
        '${media.isEncrypted}',
      );

  @override
  Future<void> setMediaKey(CallMediaKey key) async =>
      calls.add('key ${key.participantId} ${key.index}');

  @override
  Future<void> disconnect() async => calls.add('disconnect');

  @override
  Future<void> dispose() async => calls.add('dispose');

  @override
  Future<void> setMicrophone({required bool isOn}) async =>
      calls.add('microphone $isOn');

  @override
  Stream<List<CallParticipant>> watchParticipants() =>
      Stream.value(participants);
}

void main() {
  late _FakeRtc rtc;
  late _FakeToken token;
  late _FakeMedia media;
  late CallRepositoryImpl repository;

  setUp(() {
    rtc = _FakeRtc();
    token = _FakeToken();
    media = _FakeMedia();
    repository = CallRepositoryImpl(
      rtcDatasource: rtc,
      tokenDatasource: token,
      mediaDatasource: media,
    );
  });

  test('membership_always_goesToTheMatrixRtcDatasource', () async {
    // Act
    final info = repository.getRoomInfo(_room);
    await repository.endStaleOwnMembership(_room);
    await repository.joinMembership(_join);
    await repository.leaveMembership(_room);

    // Assert
    expect(info.isDirect, isTrue);
    expect(rtc.calls, ['endStale !r', 'join !r https://rtc true', 'leave !r']);
    expect(token.calls, isEmpty);
    expect(media.calls, isEmpty);
  });

  test('fetchServer_always_sendsTheMatrixTokenRequestToTheService', () async {
    // Act
    final server = await repository.fetchServer(_join);

    // Assert
    expect(server, _server);
    expect(rtc.calls, ['tokenRequest !r']);
    expect(token.calls, ['fetch https://rtc !r']);
  });

  test('media_always_goesToTheMediaDatasource', () async {
    // Act
    await repository.connectMedia(
      _server,
      const CallMediaState(isMicrophoneOn: true, isEncrypted: true),
    );
    await repository.setMicrophone(isOn: false);
    await repository.disconnectMedia();

    // Assert
    expect(media.calls, [
      'connect wss://lk.test true false true',
      'microphone false',
      'disconnect',
    ]);
    expect(rtc.calls, isEmpty);
  });

  test('watchParticipants_always_addsTheProfileOfEachMember', () async {
    // Arrange
    media.participants = const [
      CallParticipant(
        id: '@bob:hs:BOB',
        userId: '@bob:hs',
        isLocal: false,
        isMicrophoneOn: true,
        isCameraOn: false,
        isSpeaking: false,
      ),
    ];

    // Act
    final participants = await repository.watchParticipants(_room).first;

    // Assert
    expect(participants.single.displayName, '@bob:hs in !r');
    expect(participants.single.avatarUrl, Uri.parse('mxc://a'));
  });

  test('the media keys of the call go to the media until stopped', () async {
    repository.startMediaKeys(_room);
    rtc.keys.add(
      const CallMediaKey(participantId: '@b:hs:B', index: 1, key: [1]),
    );
    await pumpEventQueue();
    await repository.stopMediaKeys();
    rtc.keys.add(
      const CallMediaKey(participantId: '@b:hs:B', index: 2, key: [2]),
    );
    await pumpEventQueue();

    expect(rtc.calls, ['keys !r']);
    expect(media.calls, ['key @b:hs:B 1']);
  });
}
