import 'package:freezed_annotation/freezed_annotation.dart';

part 'unlock_ssss_state.freezed.dart';

/// Outcome of unlocking Secure Secret Storage with a recovery key and
/// self-signing the current device.
@freezed
sealed class UnlockSsssState with _$UnlockSsssState {
  /// SSSS was unlocked and the device self-signed successfully.
  const factory UnlockSsssState.success() = UnlockSsssSuccessState;

  /// Unlocking or self-signing failed.
  const factory UnlockSsssState.failure({Object? exception}) =
      UnlockSsssFailureState;
}
