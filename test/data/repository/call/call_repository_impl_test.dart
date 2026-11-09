import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/datasource/call/call_media_datasource.dart';
import 'package:twake_chat/data/datasource/call/matrix_rtc_datasource.dart';
import 'package:twake_chat/data/repository/call/call_repository_impl.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';

const _server = CallServer(url: 'wss://lk.test', token: 'jwt');

class _FakeRtc implements MatrixRtcDatasource {
  final calls = <String>[];

  @override
  CallRoomInfo getRoomInfo(String roomId) =>
      const CallRoomInfo(isEncrypted: false, isDirect: true);

  @override
  ({String? displayName, Uri? avatarUrl}) memberProfile({
    required String roomId,
    required String userId,
  }) => (displayName: '$userId in $roomId', avatarUrl: Uri.parse('mxc://a'));

  @override
  Future<CallServer> fetchServer({
    required String roomId,
    required String serviceUrl,
  }) async {
    calls.add('fetch $roomId $serviceUrl');
    return _server;
  }

  @override
  Future<void> endStaleOwnMembership(String roomId) async =>
      calls.add('endStale $roomId');

  @override
  Future<void> joinMembership({
    required String roomId,
    required String serviceUrl,
    required bool isVideo,
  }) async => calls.add('join $roomId $serviceUrl $isVideo');

  @override
  Future<void> leaveMembership(String roomId) async =>
      calls.add('leave $roomId');
}

class _FakeMedia implements CallMediaDatasource {
  final calls = <String>[];
  var participants = const <CallParticipant>[];

  @override
  Future<void> connect(
    CallServer server, {
    required bool isMicrophoneOn,
    required bool isCameraOn,
  }) async => calls.add('connect ${server.url} $isMicrophoneOn $isCameraOn');

  @override
  Future<void> disconnect() async => calls.add('disconnect');

  @override
  Future<void> dispose() async => calls.add('dispose');

  @override
  Future<void> setMicrophone({required bool isOn}) async =>
      calls.add('microphone $isOn');

  @override
  Future<void> setCamera({required bool isOn}) async =>
      calls.add('camera $isOn');

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
    expect(repository.getRoomInfo('!r').isDirect, isTrue);
    expect(
      await repository.fetchServer(roomId: '!r', serviceUrl: 'https://rtc'),
      _server,
    );
    await repository.endStaleOwnMembership('!r');
    await repository.joinMembership(
      roomId: '!r',
      serviceUrl: 'https://rtc',
      isVideo: true,
    );
    await repository.leaveMembership('!r');

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
      isMicrophoneOn: true,
      isCameraOn: false,
    );
    await repository.setMicrophone(isOn: false);
    await repository.setCamera(isOn: true);
    await repository.disconnectMedia();

    expect(media.calls, [
      'connect wss://lk.test true false',
      'microphone false',
      'camera true',
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

    final participants = await repository.watchParticipants('!r').first;

    expect(participants.single.displayName, '@bob:hs in !r');
    expect(participants.single.avatarUrl, Uri.parse('mxc://a'));
  });
}
