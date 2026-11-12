import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/datasource/call/call_media_datasource.dart';
import 'package:twake_chat/data/datasource/call/matrix_rtc_datasource.dart';
import 'package:twake_chat/data/repository/call/call_repository_impl.dart';
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
  ({String? displayName, Uri? avatarUrl}) memberProfile(
    CallRoom room,
    CallParticipant participant,
  ) => (
    displayName: '${participant.userId} in ${room.id}',
    avatarUrl: Uri.parse('mxc://a'),
  );

  @override
  Future<CallServer> fetchServer(CallJoin join) async {
    calls.add('fetch ${join.room.id} ${join.serviceUrl}');
    return _server;
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
}

class _FakeMedia implements CallMediaDatasource {
  final calls = <String>[];
  var participants = const <CallParticipant>[];

  @override
  Future<void> connect(CallServer server, CallMediaState media) async => calls
      .add('connect ${server.url} ${media.isMicrophoneOn} ${media.isCameraOn}');

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
  late _FakeMedia media;
  late CallRepositoryImpl repository;

  setUp(() {
    rtc = _FakeRtc();
    media = _FakeMedia();
    repository = CallRepositoryImpl(rtcDatasource: rtc, mediaDatasource: media);
  });

  test('the membership goes to the MatrixRTC datasource', () async {
    expect(repository.getRoomInfo(_room).isDirect, isTrue);
    expect(await repository.fetchServer(_join), _server);
    await repository.endStaleOwnMembership(_room);
    await repository.joinMembership(_join);
    await repository.leaveMembership(_room);

    expect(rtc.calls, [
      'fetch !r https://rtc',
      'endStale !r',
      'join !r https://rtc true',
      'leave !r',
    ]);
    expect(media.calls, isEmpty);
  });

  test('the media goes to the media datasource', () async {
    await repository.connectMedia(
      _server,
      const CallMediaState(isMicrophoneOn: true),
    );
    await repository.setMicrophone(isOn: false);
    await repository.disconnectMedia();

    expect(media.calls, [
      'connect wss://lk.test true false',
      'microphone false',
      'disconnect',
    ]);
    expect(rtc.calls, isEmpty);
  });

  test('watchParticipants_always_addsTheProfileOfEachMember', () async {
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

    final participants = await repository.watchParticipants(_room).first;

    expect(participants.single.displayName, '@bob:hs in !r');
    expect(participants.single.avatarUrl, Uri.parse('mxc://a'));
  });
}
