import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'unlock_ssss_state.freezed.dart';

// equal: false — Success/Failure already extend Equatable, so equality
// stays driven by the hand-written `props` below instead of freezed's
// generated `==`, which would otherwise conflict with it.
@Freezed(equal: false)
abstract class UnlockSsssLoadingState extends Success
    with _$UnlockSsssLoadingState {
  const UnlockSsssLoadingState._();

  const factory UnlockSsssLoadingState() = _UnlockSsssLoadingState;

  @override
  List<Object?> get props => [];
}

@Freezed(equal: false)
abstract class UnlockSsssSuccessState extends Success
    with _$UnlockSsssSuccessState {
  const UnlockSsssSuccessState._();

  const factory UnlockSsssSuccessState() = _UnlockSsssSuccessState;

  @override
  List<Object?> get props => [];
}

@Freezed(equal: false)
abstract class UnlockSsssFailureState extends Failure
    with _$UnlockSsssFailureState {
  const UnlockSsssFailureState._();

  const factory UnlockSsssFailureState({required dynamic exception}) =
      _UnlockSsssFailureState;

  @override
  List<Object?> get props => [exception];
}
