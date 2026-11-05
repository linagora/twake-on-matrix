import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/data/datasource/call/call_media_datasource.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_media_key.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';

class LiveKitCallMediaDatasourceImpl implements CallMediaDatasource {
  LiveKitCallMediaDatasourceImpl({
    @visibleForTesting
    lk.Room Function(lk.E2EEOptions? encryption) createRoom = _newRoom,
  }) : _createRoom = createRoom;

  static lk.Room _newRoom(lk.E2EEOptions? encryption) => lk.Room(
    roomOptions: lk.RoomOptions(
      adaptiveStream: true,
      dynacast: true,
      encryption: encryption,
    ),
  );

  final lk.Room Function(lk.E2EEOptions? encryption) _createRoom;

  /// The user of a LiveKit identity: the part before the device id.
  @visibleForTesting
  static String userIdOf(String identity) {
    final cut = identity.lastIndexOf(':');
    return cut > identity.indexOf(':') ? identity.substring(0, cut) : identity;
  }

  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _listener;
  CallConnectionFailedException? _lost;
  lk.BaseKeyProvider? _keyProvider;
  final _participants = StreamController<List<CallParticipant>>.broadcast();

  /// LiveKit gave up on the room; a listener that comes later still hears it.
  @visibleForTesting
  void onLost(Object? reason) {
    final lost = _lost = CallConnectionFailedException(cause: reason);
    _participants.addError(lost);
  }

  /// One key per device, as MatrixRTC shares them: no ratchet. HKDF, as the
  /// keys of livekit-js (`createKeyMaterialFromBuffer`).
  static Future<lk.BaseKeyProvider> _createKeyProvider() async {
    final options = rtc.KeyProviderOptions(
      sharedKey: false,
      ratchetSalt: Uint8List.fromList(lk.defaultRatchetSalt.codeUnits),
      ratchetWindowSize: 0,
      uncryptedMagicBytes: Uint8List.fromList(lk.defaultMagicBytes.codeUnits),
      keyRingSize: 256,
      keyDerivationAlgorithm: rtc.KeyDerivationAlgorithm.kHKDF,
    );
    final keyProvider = await rtc.frameCryptorFactory.createDefaultKeyProvider(
      options,
    );
    return lk.BaseKeyProvider(keyProvider, options);
  }

  @override
  Future<void> connect(CallServer server, CallMediaState media) async {
    await disconnect();
    _lost = null;
    final keyProvider = media.isEncrypted ? await _createKeyProvider() : null;
    _keyProvider = keyProvider;
    final room = _createRoom(
      keyProvider == null ? null : lk.E2EEOptions(keyProvider: keyProvider),
    );
    final listener = room.createListener()
      ..listen((_) => _emit())
      // Our own disconnect disposes the listener first: this one is LiveKit
      // giving up.
      ..on<lk.RoomDisconnectedEvent>((event) => onLost(event.reason));
    try {
      await room.connect(server.url, server.token);
    } catch (error, stackTrace) {
      await listener.dispose();
      await room.dispose();
      _rethrowErrors(error, stackTrace);
      throw CallConnectionFailedException(cause: error);
    }
    _room = room;
    _listener = listener;
    try {
      if (media.isMicrophoneOn) {
        await room.localParticipant?.setMicrophoneEnabled(true);
      }
      if (media.isCameraOn) await room.localParticipant?.setCameraEnabled(true);
    } catch (error, stackTrace) {
      await disconnect();
      _rethrowErrors(error, stackTrace);
      throw CallMediaFailedException(cause: error);
    }
    _emit();
  }

  @override
  Future<void> disconnect() async {
    final room = _room;
    final listener = _listener;
    _room = null;
    _listener = null;
    _lost = null;
    _keyProvider = null;
    await _logFailure(() async {
      await listener?.dispose();
      await room?.disconnect();
    });
    // A disconnect that times out still has to release the microphone.
    await _logFailure(() async => room?.dispose());
    _emit();
  }

  Future<void> _logFailure(Future<void> Function() run) async {
    try {
      await run();
    } catch (error, stackTrace) {
      _rethrowErrors(error, stackTrace);
      Logs().w('LiveKitCallMedia: disconnect failed', error, stackTrace);
    }
  }

  // flutter_webrtc throws Strings, not Exceptions: only Errors are bugs here.
  static void _rethrowErrors(Object error, StackTrace stackTrace) {
    if (error is Error) Error.throwWithStackTrace(error, stackTrace);
  }

  @override
  Future<void> setMediaKey(CallMediaKey key) async {
    await _keyProvider?.setRawKey(
      Uint8List.fromList(key.key),
      participantId: key.participantId,
      keyIndex: key.index,
    );
    // Published tracks keep the index they started with otherwise.
    final room = _room;
    if (key.participantId == room?.localParticipant?.identity) {
      await room?.e2eeManager?.setKeyIndex(key.index);
    }
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _participants.close();
  }

  @override
  Future<void> setMicrophone({required bool isOn}) =>
      _updateLocalParticipant((local) => local.setMicrophoneEnabled(isOn));

  Future<void> _updateLocalParticipant(
    Future<Object?> Function(lk.LocalParticipant local) run,
  ) async {
    final local = _room?.localParticipant;
    if (local == null) return;
    try {
      await run(local);
    } catch (error, stackTrace) {
      _rethrowErrors(error, stackTrace);
      throw CallMediaFailedException(cause: error);
    } finally {
      _emit();
    }
  }

  @override
  Stream<List<CallParticipant>> watchParticipants() async* {
    // Lost before anyone listened: the call still ends.
    if (_lost case final lost?) throw lost;
    yield _snapshot();
    yield* _participants.stream;
  }

  void _emit() => _participants.add(_snapshot());

  List<CallParticipant> _snapshot() {
    final room = _room;
    if (room == null) return const [];
    final local = room.localParticipant;
    return [
      if (local != null) _toParticipant(local, isLocal: true),
      for (final remote in room.remoteParticipants.values)
        _toParticipant(remote, isLocal: false),
    ];
  }

  CallParticipant _toParticipant(
    lk.Participant participant, {
    required bool isLocal,
  }) => CallParticipant(
    id: participant.identity,
    userId: userIdOf(participant.identity),
    isLocal: isLocal,
    isMicrophoneOn: participant.isMicrophoneEnabled(),
    isCameraOn: participant.isCameraEnabled(),
    isSpeaking: participant.isSpeaking,
  );
}
