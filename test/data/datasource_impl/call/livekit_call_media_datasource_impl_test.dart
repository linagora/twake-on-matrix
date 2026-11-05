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
  test('userIdOf_withADeviceId_dropsIt', () {
    // Act
    final userId = LiveKitCallMediaDatasourceImpl.userIdOf(
      '@alice:localhost:DEV',
    );

    // Assert
    expect(userId, '@alice:localhost');
  });

  test('userIdOf_withoutADeviceId_isTheIdentity', () {
    // Act
    final userId = LiveKitCallMediaDatasourceImpl.userIdOf('@alice:localhost');

    // Assert
    expect(userId, '@alice:localhost');
  });

  test('watchParticipants_afterLiveKitGaveUp_failsAsLost', () async {
    // Arrange
    final datasource = LiveKitCallMediaDatasourceImpl()..onLost('gone');

    // Act & Assert
    await expectLater(
      datasource.watchParticipants(),
      emitsError(isA<CallConnectionFailedException>()),
    );
  });

  test('watchParticipants_afterADisconnect_forgetsTheLoss', () async {
    // Arrange
    final datasource = LiveKitCallMediaDatasourceImpl()..onLost('gone');

    // Act
    await datasource.disconnect();

    // Assert
    expect(await datasource.watchParticipants().first, isEmpty);
  });

  test(
    'connect_whenTheMicrophoneFailsWithAString_disconnectsAsAMediaFailure',
    () async {
      // Arrange
      final room = _FakeRoom('Unable to getUserMedia: denied');
      final datasource = LiveKitCallMediaDatasourceImpl(
        createRoom: (_) => room,
      );

      // Act & Assert
      await expectLater(
        datasource.connect(_server, const CallMediaState(isMicrophoneOn: true)),
        throwsA(isA<CallMediaFailedException>()),
      );
      expect(room.disconnected, isTrue);
    },
  );

  test('connect_whenTheMicrophoneFailsWithAnError_rethrowsIt', () async {
    // Arrange
    final room = _FakeRoom(StateError('bug'));
    final datasource = LiveKitCallMediaDatasourceImpl(createRoom: (_) => room);

    // Act & Assert
    await expectLater(
      datasource.connect(_server, const CallMediaState(isMicrophoneOn: true)),
      throwsStateError,
    );
    expect(room.disconnected, isTrue);
  });
}
