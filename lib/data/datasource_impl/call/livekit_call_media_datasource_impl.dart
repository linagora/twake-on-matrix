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
  final _participants = StreamController<List<CallParticipant>>.broadcast();

  @override
  Future<void> connect(
    CallServer server, {
    required bool isMicrophoneOn,
    required bool isCameraOn,
  }) async {
    await disconnect();
    final room = lk.Room(
      roomOptions: const lk.RoomOptions(adaptiveStream: true, dynacast: true),
    );
    final listener = room.createListener()
      ..listen((_) => _emit())
      // Our own disconnect disposes the listener first: this one is LiveKit
      // giving up.
      ..on<lk.RoomDisconnectedEvent>(
        (event) => _participants.addError(
          CallConnectionFailedException(cause: event.reason),
        ),
      );
    try {
      await room.connect(server.url, server.token);
    } catch (error) {
      await listener.dispose();
      await room.dispose();
      throw CallConnectionFailedException(cause: error);
    }
    _room = room;
    _listener = listener;
    try {
      if (isMicrophoneOn) {
        await room.localParticipant?.setMicrophoneEnabled(true);
      }
      if (isCameraOn) await room.localParticipant?.setCameraEnabled(true);
    } catch (error) {
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

  @override
  Future<void> setCamera({required bool isOn}) =>
      _change((local) => local.setCameraEnabled(isOn));

  Future<void> _change(
    Future<Object?> Function(lk.LocalParticipant local) run,
  ) async {
    final local = _room?.localParticipant;
    if (local == null) return;
    try {
      await run(local);
    } catch (error) {
      throw CallMediaFailedException(cause: error);
    } finally {
      _emit();
    }
  }

  @override
  Stream<List<CallParticipant>> watchParticipants() async* {
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
