import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cached_recovery_key_state.freezed.dart';

// equal: false — Success/Failure already extend Equatable, so equality
// stays driven by the hand-written `props` below instead of freezed's
// generated `==`, which would otherwise conflict with it.
@Freezed(equal: false)
abstract class CachedRecoveryKeyFoundState extends Success
    with _$CachedRecoveryKeyFoundState {
  const CachedRecoveryKeyFoundState._();

  const factory CachedRecoveryKeyFoundState({required String recoveryKey}) =
      _CachedRecoveryKeyFoundState;

  @override
  List<Object?> get props => [recoveryKey];
}

@Freezed(equal: false)
abstract class CachedRecoveryKeyNotFoundState extends Success
    with _$CachedRecoveryKeyNotFoundState {
  const CachedRecoveryKeyNotFoundState._();

  const factory CachedRecoveryKeyNotFoundState() =
      _CachedRecoveryKeyNotFoundState;

  @override
  List<Object?> get props => [];
}

@Freezed(equal: false)
abstract class ReadCachedRecoveryKeyFailureState extends Failure
    with _$ReadCachedRecoveryKeyFailureState {
  const ReadCachedRecoveryKeyFailureState._();

  const factory ReadCachedRecoveryKeyFailureState({
    required dynamic exception,
  }) = _ReadCachedRecoveryKeyFailureState;

  @override
  List<Object?> get props => [exception];
}
