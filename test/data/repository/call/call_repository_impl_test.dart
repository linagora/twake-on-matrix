import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/datasource/call/call_media_datasource.dart';
import 'package:twake_chat/data/datasource/call/call_token_datasource.dart';
import 'package:twake_chat/data/datasource/call/matrix_rtc_datasource.dart';
import 'package:twake_chat/data/model/call/sfu_token_request.dart';
import 'package:twake_chat/data/repository/call/call_repository_impl.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';
import 'package:twake_chat/domain/model/call/call_ring.dart';

const _server = CallServer(url: 'wss://lk.test', token: 'jwt');
const _room = CallRoom('!r');
const _join = CallJoin(room: _room, serviceUrl: 'https://rtc', isVideo: true);

final _ring = CallRing(
  eventId: r'$ring',
  room: _room,
  senderId: '@alice:hs',
  isVideo: false,
  expiresAt: DateTime(2030),
);
final _missed = MissedCall(
  ringEventId: r'$ring',
  room: _room,
  callerId: '@alice:hs',
  sentAt: DateTime(2030),
  isVideo: false,
);

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
  Future<String> joinMembership(CallJoin join) async {
    calls.add('join ${join.room.id} ${join.serviceUrl} ${join.isVideo}');
    return r'$membership';
  }

  @override
  bool hasOtherMembers(CallRoom room) => room.id == '!busy';

  @override
  Future<void> sendRing(
    CallJoin join, {
    required String membershipEventId,
  }) async => calls.add('ring ${join.room.id} $membershipEventId');

  @override
  Future<void> declineRing(CallRing ring) async =>
      calls.add('decline ${ring.eventId}');

  @override
  Stream<List<CallRing>> watchRings() => Stream.value([_ring]);

  @override
  Stream<MissedCall> watchMissedCalls() => Stream.value(_missed);

  @override
  Future<void> ensureCallRingPushRules() async =>
      calls.add('ensureCallRingPushRules');

  @override
  Future<void> leaveMembership(CallRoom room) async =>
      calls.add('leave ${room.id}');
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
      const CallMediaState(isMicrophoneOn: true),
    );
    await repository.setMicrophone(isOn: false);
    await repository.disconnectMedia();

    // Assert
    expect(media.calls, [
      'connect wss://lk.test true false',
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

  test('joinMembership_always_returnsTheEventOfTheMembership', () async {
    expect(await repository.joinMembership(_join), r'$membership');
  });

  test('the ring goes to the MatrixRTC datasource', () async {
    expect(repository.hasOtherMembers(const CallRoom('!busy')), isTrue);
    expect(repository.hasOtherMembers(_room), isFalse);
    await repository.sendRing(_join, membershipEventId: r'$membership');
    await repository.declineRing(_ring);
    await repository.ensureCallRingPushRules();

    expect(rtc.calls, [
      r'ring !r $membership',
      r'decline $ring',
      'ensureCallRingPushRules',
    ]);
    expect(media.calls, isEmpty);
  });

  test('the rings and the missed calls come from the datasource', () async {
    expect(await repository.watchRings().first, [_ring]);
    expect(await repository.watchMissedCalls().first, _missed);
  });
}
