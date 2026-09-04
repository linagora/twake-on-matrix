import 'package:freezed_annotation/freezed_annotation.dart';

part 'cached_recovery_key_state.freezed.dart';

/// Outcome of reading the on-device cached recovery key.
@freezed
sealed class CachedRecoveryKeyState with _$CachedRecoveryKeyState {
  /// A cached recovery key was found.
  const factory CachedRecoveryKeyState.found({required String recoveryKey}) =
      CachedRecoveryKeyFoundState;

  /// No recovery key is cached for this user.
  const factory CachedRecoveryKeyState.notFound() =
      CachedRecoveryKeyNotFoundState;

  /// Reading from secure storage failed.
  const factory CachedRecoveryKeyState.failure({Object? exception}) =
      ReadCachedRecoveryKeyFailureState;
}
