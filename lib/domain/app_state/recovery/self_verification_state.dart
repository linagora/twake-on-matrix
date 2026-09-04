import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:matrix/encryption.dart';

part 'self_verification_state.freezed.dart';

/// Outcome of starting a device-to-device (SAS) self-verification request.
@freezed
sealed class SelfVerificationState with _$SelfVerificationState {
  /// The verification request was created and is awaiting the other device.
  const factory SelfVerificationState.started({
    required KeyVerification request,
  }) = StartSelfVerificationSuccessState;

  /// Starting the verification failed.
  const factory SelfVerificationState.failure({Object? exception}) =
      StartSelfVerificationFailureState;
}
