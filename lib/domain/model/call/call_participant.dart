import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_participant.freezed.dart';

/// One device in the media of the call.
@freezed
abstract class CallParticipant with _$CallParticipant {
  const factory CallParticipant({
    /// The media identity of the device, `<user id>:<device id>`.
    required String id,
    required String userId,
    required bool isLocal,
    required bool isMicrophoneOn,
    required bool isCameraOn,
    required bool isSpeaking,
    String? displayName,
    Uri? avatarUrl,
  }) = _CallParticipant;
}
