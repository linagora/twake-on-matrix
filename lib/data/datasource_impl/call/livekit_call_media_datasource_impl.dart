import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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
    @visibleForTesting
    Future<lk.BaseKeyProvider> Function() createKeyProvider = _newKeyProvider,
    @visibleForTesting
    Future<void> Function({required bool isOn, required bool isForced})
        setSpeakerOutput =
        _preferSpeaker,
    @visibleForTesting
    Future<lk.LocalVideoTrack> Function() createCameraTrack =
        lk.LocalVideoTrack.createCameraTrack,
  }) : _createRoom = createRoom,
       _createKeyProvider = createKeyProvider,
       _setSpeakerOutput = setSpeakerOutput,
       _createCameraTrack = createCameraTrack;

  static Future<void> _preferSpeaker({
    required bool isOn,
    required bool isForced,
  }) =>
      lk.AudioManager.instance.setSpeakerOutputPreferred(isOn, force: isForced);

  static lk.Room _newRoom(lk.E2EEOptions? encryption) => lk.Room(
    roomOptions: lk.RoomOptions(
      adaptiveStream: true,
      dynacast: true,
      encryption: encryption,
    ),
  );

  final lk.Room Function(lk.E2EEOptions? encryption) _createRoom;
  final Future<lk.BaseKeyProvider> Function() _createKeyProvider;
  final Future<void> Function({required bool isOn, required bool isForced})
  _setSpeakerOutput;
  final Future<lk.LocalVideoTrack> Function() _createCameraTrack;
  Future<void> _cameraChanges = Future.value();

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
  static Future<lk.BaseKeyProvider> _newKeyProvider() async {
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
      // Read by LiveKit when it starts the audio.
      await _setSpeakerOutput(isOn: media.isSpeakerOn, isForced: false);
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
      if (room.localParticipant case final local? when media.isCameraOn) {
        await _turnCameraOn(local);
      }
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
    final keyProvider = _keyProvider;
    _keyProvider = null;
    await _logFailure(() async {
      await listener?.dispose();
      await room?.disconnect();
    });
    // A disconnect that times out still has to release the microphone.
    await _logFailure(() async => room?.dispose());
    await _logFailure(() async => keyProvider?.keyProvider.dispose());
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
    try {
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
    } catch (error, stackTrace) {
      _rethrowErrors(error, stackTrace);
      Logs().w('LiveKitCallMedia: media key not set', error, stackTrace);
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

  @override
  Future<void> setCamera({required bool isOn}) {
    // One change at a time: a second "on" must see the first publication,
    // and an "off" must find it.
    final change = _cameraChanges.then(
      (_) => _updateLocalParticipant(
        (local) => isOn ? _turnCameraOn(local) : local.setCameraEnabled(false),
      ),
    );
    _cameraChanges = change.then((_) {}, onError: (_) {});
    return change;
  }

  /// livekit_client 2.13.2 leaves a new camera track running when its
  /// publication fails: this one is stopped.
  Future<void> _turnCameraOn(lk.LocalParticipant local) async {
    if (local.getTrackPublicationBySource(lk.TrackSource.camera) != null) {
      await local.setCameraEnabled(true);
      return;
    }
    final track = await _createCameraTrack();
    try {
      await local.publishVideoTrack(track);
    } catch (_) {
      await track.stop();
      rethrow;
    }
  }

  @override
  Future<void> setSpeaker({required bool isOn, required bool isForced}) async {
    try {
      await _setSpeakerOutput(isOn: isOn, isForced: isForced);
    } catch (error, stackTrace) {
      _rethrowErrors(error, stackTrace);
      throw CallMediaFailedException(cause: error);
    }
  }

  @override
  Widget? videoOf(String participantId) {
    final room = _room;
    final local = room?.localParticipant;
    final lk.Participant? participant = local?.identity == participantId
        ? local
        : room?.remoteParticipants[participantId];
    final track = participant == null ? null : _cameraOf(participant);
    if (track == null) return null;
    return lk.VideoTrackRenderer(
      track,
      key: ValueKey(track.mediaStreamTrack.id),
      fit: lk.VideoViewFit.cover,
    );
  }

  /// Null until a remote camera is subscribed: its tile shows the avatar.
  static lk.VideoTrack? _cameraOf(lk.Participant participant) {
    final publication = participant.getTrackPublicationBySource(
      lk.TrackSource.camera,
    );
    final track = publication?.track;
    if (publication == null || publication.muted) return null;
    return track is lk.VideoTrack ? track : null;
  }

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
    isCameraOn: _cameraOf(participant) != null,
    isSpeaking: participant.isSpeaking,
  );
}
