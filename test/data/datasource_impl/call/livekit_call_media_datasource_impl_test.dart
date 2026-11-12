import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:twake_chat/data/datasource_impl/call/livekit_call_media_datasource_impl.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';

const _server = CallServer(url: 'wss://lk.test', token: 'jwt');

class _FakeLocal extends Fake implements lk.LocalParticipant {
  _FakeLocal(this.failure);

  final Object failure;

  @override
  Future<lk.LocalTrackPublication?> setMicrophoneEnabled(
    bool enabled, {
    lk.AudioCaptureOptions? audioCaptureOptions,
  }) async => throw failure;
}

class _FakeRoom extends Fake implements lk.Room {
  _FakeRoom(Object failure) : localParticipant = _FakeLocal(failure);

  @override
  final events = lk.EventsEmitter<lk.RoomEvent>();

  @override
  final lk.LocalParticipant localParticipant;

  var disconnected = false;

  @override
  lk.EventsListener<lk.RoomEvent> createListener({bool synchronized = false}) =>
      lk.EventsListener<lk.RoomEvent>(events, synchronized: synchronized);

  @override
  Future<void> connect(
    String url,
    String token, {
    lk.ConnectOptions? connectOptions,
    lk.RoomOptions? roomOptions,
    lk.FastConnectOptions? fastConnectOptions,
  }) async {}

  @override
  Future<void> disconnect() async => disconnected = true;

  @override
  Future<bool> dispose() async => true;
}

void main() {
  test('the user of a LiveKit identity drops the device id', () {
    expect(
      LiveKitCallMediaDatasourceImpl.userIdOf('@alice:localhost:DEV'),
      '@alice:localhost',
    );
    expect(
      LiveKitCallMediaDatasourceImpl.userIdOf('@alice:localhost'),
      '@alice:localhost',
    );
  });

  test('watchParticipants_afterLiveKitGaveUp_failsAsLost', () async {
    final datasource = LiveKitCallMediaDatasourceImpl()..onLost('gone');

    await expectLater(
      datasource.watchParticipants(),
      emitsError(isA<CallConnectionFailedException>()),
    );
  });

  test('watchParticipants_afterADisconnect_forgetsTheLoss', () async {
    final datasource = LiveKitCallMediaDatasourceImpl()..onLost('gone');

    await datasource.disconnect();

    expect(await datasource.watchParticipants().first, isEmpty);
  });

  test(
    'connect_whenTheMicrophoneFailsWithAString_disconnectsAsAMediaFailure',
    () async {
      final room = _FakeRoom('Unable to getUserMedia: denied');
      final datasource = LiveKitCallMediaDatasourceImpl(createRoom: () => room);

      await expectLater(
        datasource.connect(_server, const CallMediaState(isMicrophoneOn: true)),
        throwsA(isA<CallMediaFailedException>()),
      );
      expect(room.disconnected, isTrue);
    },
  );

  test('connect_whenTheMicrophoneFailsWithAnError_rethrowsIt', () async {
    final room = _FakeRoom(StateError('bug'));
    final datasource = LiveKitCallMediaDatasourceImpl(createRoom: () => room);

    await expectLater(
      datasource.connect(_server, const CallMediaState(isMicrophoneOn: true)),
      throwsStateError,
    );
    expect(room.disconnected, isTrue);
  });
}
