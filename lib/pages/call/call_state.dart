import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';

part 'call_state.freezed.dart';

@freezed
sealed class CallState with _$CallState {
  const factory CallState.idle() = CallIdle;

  const factory CallState.connecting({required String roomId}) = CallConnecting;

  const factory CallState.connected({
    required String roomId,
    required bool isDirect,
    @Default([]) List<CallParticipant> participants,
    @Default(false) bool isSpeakerOn,

    /// Until then, the speaker follows the camera.
    @Default(false) bool isSpeakerChosen,
  }) = CallConnected;

  const factory CallState.failed({
    required String roomId,
    required CallException error,
  }) = CallFailed;
}
