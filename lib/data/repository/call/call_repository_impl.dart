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
  CallRoomInfo getRoomInfo(CallRoom room) => _rtc.getRoomInfo(room);

  @override
  Future<CallServer> fetchServer(CallJoin join) => _rtc.fetchServer(join);

  @override
  Future<void> endStaleOwnMembership(CallRoom room) =>
      _rtc.endStaleOwnMembership(room);

  @override
  Future<void> joinMembership(CallJoin join) => _rtc.joinMembership(join);

  @override
  Future<void> leaveMembership(CallRoom room) => _rtc.leaveMembership(room);

  @override
  Future<void> connectMedia(CallServer server, CallMediaState media) =>
      _media.connect(server, media);

  @override
  Future<void> disconnectMedia() => _media.disconnect();

  @override
  Future<void> setMicrophone({required bool isOn}) =>
      _media.setMicrophone(isOn: isOn);

  @override
  Stream<List<CallParticipant>> watchParticipants(CallRoom room) =>
      _media.watchParticipants().map(
        (participants) => [
          for (final participant in participants)
            _withProfile(room, participant),
        ],
      );

  CallParticipant _withProfile(CallRoom room, CallParticipant participant) {
    final profile = _rtc.memberProfile(room, participant);
    return participant.copyWith(
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
    );
  }

  @override
  Stream<void> watchRoomEncrypted(CallRoom room) =>
      _rtc.watchRoomEncrypted(room);
}
