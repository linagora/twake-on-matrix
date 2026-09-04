import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_recovery_key_state.freezed.dart';

/// Outcome of caching the recovery key in on-device secure storage.
@freezed
sealed class StoreRecoveryKeyState with _$StoreRecoveryKeyState {
  /// The recovery key was written to secure storage.
  const factory StoreRecoveryKeyState.success() = StoreRecoveryKeySuccessState;

  /// Writing to secure storage failed.
  const factory StoreRecoveryKeyState.failure({Object? exception}) =
      StoreRecoveryKeyFailureState;
}
