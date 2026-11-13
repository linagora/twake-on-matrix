import 'dart:async';

import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';
import 'package:twake_chat/domain/model/call/call_ring.dart';
import 'package:twake_chat/domain/repository/call/call_repository.dart';

const testMembershipEventId = r'$membership';

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
    this.roomInfo = const CallRoomInfo(
      isEncrypted: false,
      isDirect: false,
      canJoin: true,
    ),
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
  CallException? declineError;
  Object? staleError;
  Object? ringError;
  Object? pushRulesError;

  /// What `hasOtherMembers` answers.
  bool othersInCall = false;
  CallException? disconnectError;
  Completer<void>? connectGate;
  Completer<void>? leaveGate;
  Completer<void>? joinGate;

  final calls = <String>[];
  final participants = StreamController<List<CallParticipant>>.broadcast();
  final encryptions = StreamController<void>.broadcast();
  final rings = StreamController<List<CallRing>>.broadcast();
  final missedCalls = StreamController<MissedCall>.broadcast();

  @override
  Stream<void> watchRoomEncrypted(CallRoom room) => encryptions.stream;

  @override
  CallRoomInfo getRoomInfo(CallRoom room) => roomInfo;

  @override
  Future<CallServer> fetchServer(CallJoin join) async {
    calls.add('fetchServer ${join.room.id} ${join.serviceUrl}');
    if (fetchError case final error?) throw error;
    return testServer;
  }

  @override
  Future<void> endStaleOwnMembership(CallRoom room) async {
    calls.add('endStale ${room.id}');
    if (staleError case final error?) throw error;
  }

  @override
  Future<String> joinMembership(CallJoin join) async {
    calls.add('join ${join.room.id} video=${join.isVideo}');
    await joinGate?.future;
    if (joinError case final error?) throw error;
    return testMembershipEventId;
  }

  @override
  bool hasOtherMembers(CallRoom room) => othersInCall;

  @override
  Future<void> sendRing(
    CallJoin join, {
    required String membershipEventId,
  }) async {
    calls.add(
      'ring ${join.room.id} video=${join.isVideo} '
      'membership=$membershipEventId',
    );
    if (ringError case final error?) throw error;
  }

  @override
  Future<void> declineRing(CallRing ring) async {
    calls.add('decline ${ring.eventId}');
    if (declineError case final error?) throw error;
  }

  @override
  Stream<List<CallRing>> watchRings() => rings.stream;

  @override
  Stream<MissedCall> watchMissedCalls() => missedCalls.stream;

  @override
  Future<void> ensureCallRingPushRules() async {
    calls.add('ensureCallRingPushRules');
    if (pushRulesError case final error?) throw error;
  }

  @override
  Future<void> leaveMembership(CallRoom room) async {
    calls.add('leave ${room.id}');
    await leaveGate?.future;
    if (leaveError case final error?) throw error;
  }

  @override
  Future<void> connectMedia(CallServer server, CallMediaState media) async {
    calls.add('connect mic=${media.isMicrophoneOn} camera=${media.isCameraOn}');
    await connectGate?.future;
    if (connectError case final error?) throw error;
  }

  @override
  Future<void> disconnectMedia() async {
    calls.add('disconnect');
    if (disconnectError case final error?) throw error;
  }

  @override
  Future<void> setMicrophone({required bool isOn}) async {
    calls.add('microphone $isOn');
    if (mediaError case final error?) throw error;
  }

  @override
  Stream<List<CallParticipant>> watchParticipants(CallRoom room) =>
      participants.stream;
}
