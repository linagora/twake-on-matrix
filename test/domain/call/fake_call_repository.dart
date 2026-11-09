import 'dart:async';

import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';
import 'package:twake_chat/domain/repository/call/call_repository.dart';

const testServer = CallServer(url: 'wss://lk.test', token: 'jwt');

CallParticipant participant(String id, {bool isLocal = false}) =>
    CallParticipant(
      id: id,
      userId: id.substring(0, id.lastIndexOf(':')),
      isLocal: isLocal,
      isMicrophoneOn: true,
      isCameraOn: false,
      isSpeaking: false,
    );

class FakeCallRepository implements CallRepository {
  FakeCallRepository({
    this.roomInfo = const CallRoomInfo(isEncrypted: false, isDirect: false),
    this.fetchError,
    this.connectError,
    this.joinError,
    this.leaveError,
    this.mediaError,
  });

  CallRoomInfo roomInfo;
  CallException? fetchError;
  CallException? connectError;
  CallException? joinError;
  CallException? leaveError;
  CallException? mediaError;

  final calls = <String>[];
  final participants = StreamController<List<CallParticipant>>.broadcast();

  @override
  CallRoomInfo getRoomInfo(String roomId) => roomInfo;

  @override
  Future<CallServer> fetchServer({
    required String roomId,
    required String serviceUrl,
  }) async {
    calls.add('fetchServer $roomId $serviceUrl');
    if (fetchError case final error?) throw error;
    return testServer;
  }

  @override
  Future<void> endStaleOwnMembership(String roomId) async =>
      calls.add('endStale $roomId');

  @override
  Future<void> joinMembership({
    required String roomId,
    required String serviceUrl,
    required bool isVideo,
  }) async {
    calls.add('join $roomId video=$isVideo');
    if (joinError case final error?) throw error;
  }

  @override
  Future<void> leaveMembership(String roomId) async {
    calls.add('leave $roomId');
    if (leaveError case final error?) throw error;
  }

  @override
  Future<void> connectMedia(
    CallServer server, {
    required bool isMicrophoneOn,
    required bool isCameraOn,
  }) async {
    calls.add('connect mic=$isMicrophoneOn camera=$isCameraOn');
    if (connectError case final error?) throw error;
  }

  @override
  Future<void> disconnectMedia() async => calls.add('disconnect');

  @override
  Future<void> setMicrophone({required bool isOn}) async {
    calls.add('microphone $isOn');
    if (mediaError case final error?) throw error;
  }

  @override
  Future<void> setCamera({required bool isOn}) async {
    calls.add('camera $isOn');
    if (mediaError case final error?) throw error;
  }

  @override
  Stream<List<CallParticipant>> watchParticipants(String roomId) =>
      participants.stream;
}
