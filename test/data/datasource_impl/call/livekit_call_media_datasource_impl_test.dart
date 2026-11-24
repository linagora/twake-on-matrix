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

class _FakeLocal extends Fake implements lk.LocalParticipant {
  _FakeLocal(this.failure);

  final Object? failure;

  @override
  String get identity => _ownIdentity;

  @override
  bool isMicrophoneEnabled() => false;

  final cameraChanges = <bool>[];

  @override
  lk.LocalTrackPublication? getTrackPublicationBySource(
    lk.TrackSource source,
  ) => null;

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
    Object? speakerFailure;

    setUp(() {
      room = _FakeRoom();
      speakerFailure = null;
      datasource = LiveKitCallMediaDatasourceImpl(
        createRoom: (_) => room,
        setSpeakerOutput: ({required isOn, required isForced}) async {
          room.speakerChanges.add('$isOn forced=$isForced');
          if (speakerFailure case final failure?) throw failure;
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

    test('setSpeaker_whenTheDeviceRefuses_failsAsMedia', () async {
      // Arrange
      speakerFailure = 'no audio session';

      // Act & Assert
      await expectLater(
        datasource.setSpeaker(isOn: true, isForced: true),
        throwsA(isA<CallMediaFailedException>()),
      );
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
      expect(room.localParticipant.cameraChanges, [true]);
    });

    test('videoOf_withoutACamera_isNull', () async {
      // Arrange
      await datasource.connect(
        _server,
        const CallMediaState(isMicrophoneOn: false, isEncrypted: false),
      );

      // Act & Assert
      expect(datasource.videoOf(_ownIdentity), isNull);
    });
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
