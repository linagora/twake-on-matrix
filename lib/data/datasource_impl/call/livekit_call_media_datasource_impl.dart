import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/data/datasource/call/call_media_datasource.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';

class LiveKitCallMediaDatasourceImpl implements CallMediaDatasource {
  /// The user of a LiveKit identity: the part before the device id.
  @visibleForTesting
  static String userIdOf(String identity) {
    final cut = identity.lastIndexOf(':');
    return cut > identity.indexOf(':') ? identity.substring(0, cut) : identity;
  }

  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _listener;
  CallConnectionFailedException? _lost;
  final _participants = StreamController<List<CallParticipant>>.broadcast();

  /// LiveKit gave up on the room; a listener that comes later still hears it.
  @visibleForTesting
  void onLost(Object? reason) {
    final lost = _lost = CallConnectionFailedException(cause: reason);
    _participants.addError(lost);
  }

  @override
  Future<void> connect(CallServer server, CallMediaState media) async {
    await disconnect();
    _lost = null;
    final room = lk.Room(
      roomOptions: const lk.RoomOptions(adaptiveStream: true, dynacast: true),
    );
    final listener = room.createListener()
      ..listen((_) => _emit())
      // Our own disconnect disposes the listener first: this one is LiveKit
      // giving up.
      ..on<lk.RoomDisconnectedEvent>((event) => onLost(event.reason));
    try {
      await room.connect(server.url, server.token);
    } on Exception catch (error) {
      await listener.dispose();
      await room.dispose();
      throw CallConnectionFailedException(cause: error);
    }
    _room = room;
    _listener = listener;
    try {
      if (media.isMicrophoneOn) {
        await room.localParticipant?.setMicrophoneEnabled(true);
      }
      if (media.isCameraOn) await room.localParticipant?.setCameraEnabled(true);
    } on Exception catch (error) {
      await disconnect();
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
    } on Exception catch (error, stackTrace) {
      Logs().w('LiveKitCallMedia: disconnect failed', error, stackTrace);
    }
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _participants.close();
  }

  @override
  Future<void> setMicrophone({required bool isOn}) =>
      _change((local) => local.setMicrophoneEnabled(isOn));

  Future<void> _change(
    Future<Object?> Function(lk.LocalParticipant local) run,
  ) async {
    final local = _room?.localParticipant;
    if (local == null) return;
    try {
      await run(local);
    } on Exception catch (error) {
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
