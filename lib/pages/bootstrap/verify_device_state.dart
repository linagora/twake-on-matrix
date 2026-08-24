import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:matrix/encryption.dart';

part 'verify_device_state.freezed.dart';

/// UI-shape state for `VerifyDeviceScreen` — the chooser plus every
/// sub-flow it can show (SAS verification, recovery-key form,
/// reset-encryption, and the caller's own "Retry automatically" outcome).
@freezed
sealed class VerifyDeviceUiState with _$VerifyDeviceUiState {
  const factory VerifyDeviceUiState.chooser({
    @Default(false) bool isStartingVerification,
  }) = VerifyDeviceChooserState;

  /// Mirrors `KeyVerificationState` while a SAS request from "Use another
  /// device" is in flight.
  ///
  /// [requestState] must be [request]'s `.state` captured once by the
  /// caller at construction time — [request] itself is a live, mutable SDK
  /// object whose `.state` keeps changing after this object is built, so
  /// comparing two [VerifyDeviceSasState]s by reading `request.state` live
  /// (rather than a frozen copy) always sees the same, already-mutated
  /// value on both sides and never detects a change.
  const factory VerifyDeviceUiState.sas({
    required KeyVerification request,
    required KeyVerificationState requestState,
  }) = VerifyDeviceSasState;

  const factory VerifyDeviceUiState.recoveryKeyForm({
    String? initialValue,
    String? errorText,
  }) = VerifyDeviceRecoveryKeyFormState;

  const factory VerifyDeviceUiState.resetConfirm({
    @Default(false) bool isResetting,
  }) = VerifyDeviceResetConfirmState;

  const factory VerifyDeviceUiState.resetComplete() =
      VerifyDeviceResetCompleteState;

  const factory VerifyDeviceUiState.success() = VerifyDeviceSuccessState;

  /// Failure surfaced from the caller's own "Retry automatically" flow —
  /// distinct from `VerifyDeviceSasState`'s `KeyVerificationState.error`,
  /// since retry never ran the SAS sub-flow at all.
  const factory VerifyDeviceUiState.retryError() = VerifyDeviceRetryErrorState;
}
