import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_video_call_state.freezed.dart';

@freezed
sealed class ChatVideoCallState with _$ChatVideoCallState {
  const factory ChatVideoCallState.idle() = ChatVideoCallIdle;

  const factory ChatVideoCallState.starting() = ChatVideoCallStarting;
}
