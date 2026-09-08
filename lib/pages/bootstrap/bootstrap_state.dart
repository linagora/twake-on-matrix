import 'package:freezed_annotation/freezed_annotation.dart';

part 'bootstrap_state.freezed.dart';

@freezed
sealed class BootstrapUiState with _$BootstrapUiState {
  const factory BootstrapUiState.loading() = BootstrapLoadingState;

  const factory BootstrapUiState.recoveryKeyDisplay({
    required String recoveryKey,
    required bool supportsSecureStorage,
    @Default(false) bool storeInSecureStorage,
    @Default(false) bool recoveryKeyCopied,
  }) = BootstrapRecoveryKeyDisplayState;

  const factory BootstrapUiState.verifyDevice({
    String? prefilledRecoveryKey,
    @Default(false) bool retrySucceeded,
    @Default(false) bool retryFailed,
  }) = BootstrapVerifyDeviceState;

  const factory BootstrapUiState.legacyError() = BootstrapLegacyErrorState;

  const factory BootstrapUiState.legacyDone() = BootstrapLegacyDoneState;
}
