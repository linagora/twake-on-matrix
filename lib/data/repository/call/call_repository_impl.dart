import 'package:twake_chat/data/datasource/call/call_media_datasource.dart';
import 'package:twake_chat/data/datasource/call/matrix_rtc_datasource.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';
import 'package:twake_chat/domain/repository/call/call_repository.dart';

class CallRepositoryImpl implements CallRepository {
  const CallRepositoryImpl({
    required MatrixRtcDatasource rtcDatasource,
    required CallMediaDatasource mediaDatasource,
  }) : _rtc = rtcDatasource,
       _media = mediaDatasource;

  final MatrixRtcDatasource _rtc;
  final CallMediaDatasource _media;

  @override
  CallRoomInfo getRoomInfo(String roomId) => _rtc.getRoomInfo(roomId);

  @override
  Future<CallServer> fetchServer({
    required String roomId,
    required String serviceUrl,
  }) => _rtc.fetchServer(roomId: roomId, serviceUrl: serviceUrl);

  @override
  Future<void> endStaleOwnMembership(String roomId) =>
      _rtc.endStaleOwnMembership(roomId);

  @override
  Future<void> joinMembership({
    required String roomId,
    required String serviceUrl,
    required bool isVideo,
  }) => _rtc.joinMembership(
    roomId: roomId,
    serviceUrl: serviceUrl,
    isVideo: isVideo,
  );

  @override
  Future<void> leaveMembership(String roomId) => _rtc.leaveMembership(roomId);

  @override
  Future<void> connectMedia(
    CallServer server, {
    required bool isMicrophoneOn,
    required bool isCameraOn,
  }) => _media.connect(
    server,
    isMicrophoneOn: isMicrophoneOn,
    isCameraOn: isCameraOn,
  );

  @override
  Future<void> disconnectMedia() => _media.disconnect();

  @override
  Future<void> setMicrophone({required bool isOn}) =>
      _media.setMicrophone(isOn: isOn);

  @override
  Stream<List<CallParticipant>> watchParticipants(String roomId) =>
      _media.watchParticipants().map(
        (participants) => [
          for (final participant in participants)
            _withProfile(roomId, participant),
        ],
      );

  CallParticipant _withProfile(String roomId, CallParticipant participant) {
    final profile = _rtc.memberProfile(
      roomId: roomId,
      userId: participant.userId,
    );
    return participant.copyWith(
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
    );
  }

  @override
  Stream<void> watchRoomEncrypted(String roomId) =>
      _rtc.watchRoomEncrypted(roomId);
}
