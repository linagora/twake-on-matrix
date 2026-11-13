import 'dart:async';

import 'package:twake_chat/data/datasource/call/call_media_datasource.dart';
import 'package:twake_chat/data/datasource/call/call_token_datasource.dart';
import 'package:twake_chat/data/datasource/call/matrix_rtc_datasource.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';
import 'package:twake_chat/domain/repository/call/call_repository.dart';
import 'package:twake_chat/utils/logging/log_orchestrator.dart';
import 'package:twake_chat/utils/logging/log_types.dart';

class CallRepositoryImpl implements CallRepository {
  CallRepositoryImpl({
    required MatrixRtcDatasource rtcDatasource,
    required CallTokenDatasource tokenDatasource,
    required CallMediaDatasource mediaDatasource,
  }) : _rtc = rtcDatasource,
       _token = tokenDatasource,
       _media = mediaDatasource;

  final MatrixRtcDatasource _rtc;
  final CallTokenDatasource _token;
  final CallMediaDatasource _media;
  StreamSubscription<Object?>? _mediaKeys;

  @override
  CallRoomInfo getRoomInfo(CallRoom room) => _rtc.getRoomInfo(room);

  @override
  Future<CallServer> fetchServer(CallJoin join) async => _token.fetchServer(
    join.serviceUrl,
    await _rtc.createTokenRequest(join.room),
  );

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
  void startMediaKeys(CallRoom room) {
    unawaited(_mediaKeys?.cancel());
    _mediaKeys = _rtc
        .watchMediaKeys(room)
        .asyncMap(_media.setMediaKey)
        .listen(null, onError: _onMediaKeyFailed);
  }

  /// The call goes on: the next key of that device replaces this one.
  static void _onMediaKeyFailed(Object error, StackTrace stackTrace) =>
      LogOrchestrator().log(
        LogEntry(
          message: 'CallRepository: media key not applied',
          level: LogLevel.warn,
          error: error,
          stackTrace: stackTrace,
        ),
      );

  @override
  Future<void> stopMediaKeys() async {
    final mediaKeys = _mediaKeys;
    _mediaKeys = null;
    await mediaKeys?.cancel();
  }

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
    final profile = _rtc.getMemberProfile(room, participant);
    return participant.copyWith(
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
    );
  }

  @override
  Stream<void> watchRoomEncrypted(CallRoom room) =>
      _rtc.watchRoomEncrypted(room);
}
