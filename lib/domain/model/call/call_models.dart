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
    @Default(true) bool canJoin,
  }) = _CallRoomInfo;
}
