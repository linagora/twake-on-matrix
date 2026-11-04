import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';

/// All failures are `CallException`s.
abstract class CallRepository {
  CallRoomInfo getRoomInfo(String roomId);

  Future<CallServer> fetchServer({
    required String roomId,
    required String serviceUrl,
  });

  /// Ends a membership of this device left by an earlier run.
  Future<void> endStaleOwnMembership(String roomId);

  Future<void> joinMembership({
    required String roomId,
    required String serviceUrl,
    required bool isVideo,
  });

  Future<void> leaveMembership(String roomId);

  Future<void> connectMedia(
    CallServer server, {
    required bool isMicrophoneOn,
    required bool isCameraOn,
  });

  Future<void> disconnectMedia();

  Future<void> setMicrophone({required bool isOn});

  Future<void> setCamera({required bool isOn});

  /// Emits the participants on each change while the media is connected.
  Stream<List<CallParticipant>> watchParticipants();
}
