import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_models.freezed.dart';

/// Where to join the media of a call, as the token service (MSC4195) gives it.
@freezed
abstract class CallServer with _$CallServer {
  const factory CallServer({required String url, required String token}) =
      _CallServer;
}

/// The room the call is in, as the call needs to know it.
@freezed
abstract class CallRoomInfo with _$CallRoomInfo {
  const factory CallRoomInfo({
    required bool isEncrypted,
    required bool isDirect,
    required bool canJoin,
  }) = _CallRoomInfo;
}

/// The room of a call, by its Matrix id.
@freezed
abstract class CallRoom with _$CallRoom {
  const factory CallRoom(String id) = _CallRoom;
}

/// What joining the call of a room needs.
@freezed
abstract class CallJoin with _$CallJoin {
  const factory CallJoin({
    required CallRoom room,
    required String serviceUrl,
    @Default(false) bool isVideo,
  }) = _CallJoin;
}

/// The own media of a call.
@freezed
abstract class CallMediaState with _$CallMediaState {
  const factory CallMediaState({
    required bool isMicrophoneOn,
    @Default(false) bool isCameraOn,
  }) = _CallMediaState;
}

/// A device in a call: its user and its device id.
@freezed
abstract class CallDevice with _$CallDevice {
  const factory CallDevice({required String userId, required String deviceId}) =
      _CallDevice;
}
