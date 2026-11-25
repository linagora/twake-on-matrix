import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:twake_chat/data/datasource_impl/call/livekit_call_media_datasource_impl.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_media_key.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';

const _server = CallServer(url: 'wss://lk.test', token: 'jwt');
const _ownIdentity = '@alice:localhost:DEV';

class _FakeCameraTrack extends Fake implements lk.LocalVideoTrack {
  var stopped = false;
  Object? stopFailure;

  @override
  Future<bool> stop() async {
    stopped = true;
    if (stopFailure case final failure?) throw failure;
    return true;
  }
}

class _FakeVideoPublication extends Fake
    implements lk.LocalTrackPublication<lk.LocalVideoTrack> {
  @override
  bool get muted => false;

  @override
  lk.LocalVideoTrack? get track => null;
}

class _FakeLocal extends Fake implements lk.LocalParticipant {
  _FakeLocal(this.failure);

  final Object? failure;

  @override
  String get identity => _ownIdentity;

  @override
  bool isMicrophoneEnabled() => false;

  final cameraChanges = <bool>[];
  final publishedTracks = <lk.LocalVideoTrack>[];
  Object? publishFailure;

  @override
  Future<lk.LocalTrackPublication<lk.LocalVideoTrack>> publishVideoTrack(
    lk.LocalVideoTrack track, {
    lk.VideoPublishOptions? publishOptions,
  }) async {
    if (publishFailure case final failure?) throw failure;
    publishedTracks.add(track);
    return camera = _FakeVideoPublication();
  }

  _FakeVideoPublication? camera;

  @override
  lk.LocalTrackPublication? getTrackPublicationBySource(
    lk.TrackSource source,
  ) => source == lk.TrackSource.camera ? camera : null;

  @override
  bool get isSpeaking => false;

  @override
  Future<lk.LocalTrackPublication?> setMicrophoneEnabled(
    bool enabled, {
    lk.AudioCaptureOptions? audioCaptureOptions,
  }) async => throw failure!;

  @override
  Future<lk.LocalTrackPublication?> setCameraEnabled(
    bool enabled, {
    lk.CameraCaptureOptions? cameraCaptureOptions,
  }) async {
    cameraChanges.add(enabled);
    if (failure case final failure?) throw failure;
    if (camera case final camera?) return camera;
    return null;
  }
}

class _FakeE2EEManager extends Fake implements lk.E2EEManager {
  final keyIndexes = <int>[];

  @override
  Future<void> setKeyIndex(int keyIndex, {String? participantIdentity}) async =>
      keyIndexes.add(keyIndex);
}

class _FakeRtcKeyProvider extends Fake implements rtc.KeyProvider {
  final keys = <String>[];
  var disposed = false;

  @override
  Future<bool> setKey({
    required String participantId,
    required int index,
    required Uint8List key,
  }) async {
    keys.add('$participantId@$index');
    return true;
  }

  @override
  Future<void> dispose() async => disposed = true;
}

class _FakeRoom extends Fake implements lk.Room {
  _FakeRoom([Object? failure]) : localParticipant = _FakeLocal(failure);

  final speakerChanges = <String>[];

  /// The room connection and the audio route changes, in order.
  final steps = <String>[];

  @override
  final _FakeE2EEManager e2eeManager = _FakeE2EEManager();

  @override
  final events = lk.EventsEmitter<lk.RoomEvent>();

  @override
  final _FakeLocal localParticipant;

  @override
  final remoteParticipants = UnmodifiableMapView<String, lk.RemoteParticipant>(
    {},
  );

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
  }) async => steps.add('connect');

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
        datasource.connect(
          _server,
          const CallMediaState(isMicrophoneOn: true, isEncrypted: false),
        ),
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
      datasource.connect(
        _server,
        const CallMediaState(isMicrophoneOn: true, isEncrypted: false),
      ),
      throwsStateError,
    );
    expect(room.disconnected, isTrue);
  });

  group('audio output and camera', () {
    late _FakeRoom room;
    late LiveKitCallMediaDatasourceImpl datasource;
    late _FakeCameraTrack cameraTrack;
    late int camerasCreated;
    Completer<void>? captureGate;

    setUp(() {
      room = _FakeRoom();
      cameraTrack = _FakeCameraTrack();
      camerasCreated = 0;
      captureGate = null;
      datasource = LiveKitCallMediaDatasourceImpl(
        createRoom: (_) => room,
        createCameraTrack: () async {
          camerasCreated++;
          await captureGate?.future;
          return cameraTrack;
        },
        setSpeakerOutput: ({required isOn, required isForced}) async {
          room.speakerChanges.add('$isOn forced=$isForced');
          room.steps.add('speaker');
        },
      );
    });

    test('connect_inAVideoCall_prefersTheSpeaker', () async {
      // Act
      await datasource.connect(
        _server,
        const CallMediaState(
          isMicrophoneOn: false,
          isSpeakerOn: true,
          isEncrypted: false,
        ),
      );

      // Assert
      expect(room.speakerChanges, ['true forced=false']);
    });

    test('connect_inAnAudioCall_prefersTheEarpiece', () async {
      // Act
      await datasource.connect(
        _server,
        const CallMediaState(isMicrophoneOn: false, isEncrypted: false),
      );

      // Assert
      expect(room.speakerChanges, ['false forced=false']);
    });

    test('connect_always_routesTheAudioOnceConnected', () async {
      // Act
      await datasource.connect(
        _server,
        const CallMediaState(isMicrophoneOn: false, isEncrypted: false),
      );

      // Assert
      expect(room.steps, ['connect', 'speaker']);
    });

    test('setCamera_inTheCall_turnsTheOwnCameraOn', () async {
      // Arrange
      await datasource.connect(
        _server,
        const CallMediaState(isMicrophoneOn: false, isEncrypted: false),
      );

      // Act
      await datasource.setCamera(isOn: true);

      // Assert
      expect(room.localParticipant.publishedTracks, [cameraTrack]);
      expect(cameraTrack.stopped, isFalse);
    });

    test('setCamera_whenThePublicationFails_stopsTheNewTrack', () async {
      // Arrange
      await datasource.connect(
        _server,
        const CallMediaState(isMicrophoneOn: false, isEncrypted: false),
      );
      room.localParticipant.publishFailure = 'publish timed out';

      // Act & Assert
      await expectLater(
        datasource.setCamera(isOn: true),
        throwsA(isA<CallMediaFailedException>()),
      );
      expect(cameraTrack.stopped, isTrue);
    });

    test('setCamera_onTwiceAtOnce_capturesOneCamera', () async {
      // Arrange
      await datasource.connect(
        _server,
        const CallMediaState(isMicrophoneOn: false, isEncrypted: false),
      );
      captureGate = Completer<void>();

      // Act
      final first = datasource.setCamera(isOn: true);
      final second = datasource.setCamera(isOn: true);
      captureGate!.complete();
      await Future.wait([first, second]);

      // Assert
      expect(camerasCreated, 1);
      expect(room.localParticipant.publishedTracks, [cameraTrack]);
    });

    test('setCamera_offWhileTurningOn_turnsOffThePublishedCamera', () async {
      // Arrange
      await datasource.connect(
        _server,
        const CallMediaState(isMicrophoneOn: false, isEncrypted: false),
      );
      captureGate = Completer<void>();
      final on = datasource.setCamera(isOn: true);

      // Act
      final off = datasource.setCamera(isOn: false);
      await pumpEventQueue();
      final offBeforePublish = room.localParticipant.cameraChanges.toList();
      captureGate!.complete();
      await Future.wait([on, off]);

      // Assert
      expect(offBeforePublish, isEmpty);
      expect(room.localParticipant.publishedTracks, [cameraTrack]);
      expect(room.localParticipant.cameraChanges, [false]);
    });

    test('setCamera_off_turnsTheOwnCameraOff', () async {
      // Arrange
      await datasource.connect(
        _server,
        const CallMediaState(isMicrophoneOn: false, isEncrypted: false),
      );

      // Act
      await datasource.setCamera(isOn: false);

      // Assert
      expect(room.localParticipant.cameraChanges, [false]);
    });

    test('watchParticipants_withoutACamera_givesNoVideo', () async {
      // Arrange
      await datasource.connect(
        _server,
        const CallMediaState(isMicrophoneOn: false, isEncrypted: false),
      );

      // Act
      final own = (await datasource.watchParticipants().first).single;

      // Assert
      expect(own.isCameraOn, isFalse);
      expect(own.video, isNull);
    });

    test('setCamera_whenLeftWhileTheCameraOpens_stopsTheTrack', () async {
      // Arrange
      await datasource.connect(
        _server,
        const CallMediaState(isMicrophoneOn: false, isEncrypted: false),
      );
      captureGate = Completer<void>();
      final camera = datasource.setCamera(isOn: true);
      await pumpEventQueue();

      // Act
      await datasource.disconnect();
      captureGate!.complete();
      await camera;

      // Assert
      expect(cameraTrack.stopped, isTrue);
      expect(room.localParticipant.publishedTracks, isEmpty);
    });

    test(
      'setCamera_whenTheStopFailsAfterAFailedPublish_keepsThePublishError',
      () async {
        // Arrange
        await datasource.connect(
          _server,
          const CallMediaState(isMicrophoneOn: false, isEncrypted: false),
        );
        room.localParticipant.publishFailure = 'publish timed out';
        cameraTrack.stopFailure = 'already stopped';

        // Act & Assert
        await expectLater(
          datasource.setCamera(isOn: true),
          throwsA(
            isA<CallMediaFailedException>().having(
              (error) => error.cause,
              'cause',
              'publish timed out',
            ),
          ),
        );
      },
    );
  });

  group('in an encrypted call', () {
    late _FakeRoom room;
    late _FakeRtcKeyProvider nativeKeys;
    late lk.BaseKeyProvider keyProvider;
    late LiveKitCallMediaDatasourceImpl datasource;
    lk.E2EEOptions? encryption;

    setUp(() async {
      room = _FakeRoom();
      nativeKeys = _FakeRtcKeyProvider();
      keyProvider = lk.BaseKeyProvider(
        nativeKeys,
        rtc.KeyProviderOptions(
          sharedKey: false,
          ratchetSalt: Uint8List(0),
          ratchetWindowSize: 0,
        ),
      );
      encryption = null;
      datasource = LiveKitCallMediaDatasourceImpl(
        createRoom: (options) {
          encryption = options;
          return room;
        },
        createKeyProvider: () async => keyProvider,
      );
      await datasource.connect(
        _server,
        const CallMediaState(isMicrophoneOn: false, isEncrypted: true),
      );
    });

    test('connect_always_encryptsWithTheKeyProvider', () {
      // Assert
      expect(encryption?.keyProvider, same(keyProvider));
    });

    test('setMediaKey_withOwnKey_usesItsIndex', () async {
      // Act
      await datasource.setMediaKey(
        const CallMediaKey(participantId: _ownIdentity, index: 3, key: [1]),
      );

      // Assert
      expect(nativeKeys.keys, ['$_ownIdentity@3']);
      expect(room.e2eeManager.keyIndexes, [3]);
    });

    test('setMediaKey_withARemoteKey_keepsOwnIndex', () async {
      // Act
      await datasource.setMediaKey(
        const CallMediaKey(
          participantId: '@bob:localhost:B',
          index: 3,
          key: [1],
        ),
      );

      // Assert
      expect(nativeKeys.keys, ['@bob:localhost:B@3']);
      expect(room.e2eeManager.keyIndexes, isEmpty);
    });

    test('disconnect_always_disposesTheKeyProvider', () async {
      // Act
      await datasource.disconnect();

      // Assert
      expect(nativeKeys.disposed, isTrue);
    });
  });

  test('connect_inAnUnencryptedCall_createsNoKeyProvider', () async {
    // Arrange
    lk.E2EEOptions? encryption;
    var created = false;
    final datasource = LiveKitCallMediaDatasourceImpl(
      createRoom: (options) {
        encryption = options;
        return _FakeRoom();
      },
      createKeyProvider: () async {
        created = true;
        throw StateError('unexpected');
      },
    );

    // Act
    await datasource.connect(
      _server,
      const CallMediaState(isMicrophoneOn: false, isEncrypted: false),
    );

    // Assert
    expect(encryption, isNull);
    expect(created, isFalse);
  });
}
