import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:matrix/encryption.dart';

part 'self_verification_state.freezed.dart';

// equal: false — Success/Failure already extend Equatable, so equality
// stays driven by the hand-written `props` below instead of freezed's
// generated `==`, which would otherwise conflict with it.
@Freezed(equal: false)
abstract class StartSelfVerificationLoadingState extends Success
    with _$StartSelfVerificationLoadingState {
  const StartSelfVerificationLoadingState._();

  const factory StartSelfVerificationLoadingState() =
      _StartSelfVerificationLoadingState;

  @override
  List<Object?> get props => [];
}

@Freezed(equal: false)
abstract class StartSelfVerificationSuccessState extends Success
    with _$StartSelfVerificationSuccessState {
  const StartSelfVerificationSuccessState._();

  const factory StartSelfVerificationSuccessState({
    required KeyVerification request,
  }) = _StartSelfVerificationSuccessState;

  @override
  List<Object?> get props => [request];
}

@Freezed(equal: false)
abstract class StartSelfVerificationFailureState extends Failure
    with _$StartSelfVerificationFailureState {
  const StartSelfVerificationFailureState._();

  const factory StartSelfVerificationFailureState({
    required dynamic exception,
  }) = _StartSelfVerificationFailureState;

  @override
  List<Object?> get props => [exception];
}
