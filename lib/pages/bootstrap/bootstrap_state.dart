import 'package:equatable/equatable.dart';

sealed class BootstrapUiState extends Equatable {
  const BootstrapUiState();

  @override
  List<Object?> get props => [];
}

class BootstrapLoadingState extends BootstrapUiState {
  const BootstrapLoadingState();
}

class BootstrapRecoveryKeyDisplayState extends BootstrapUiState {
  final String recoveryKey;
  final bool supportsSecureStorage;
  final bool storeInSecureStorage;
  final bool recoveryKeyCopied;

  const BootstrapRecoveryKeyDisplayState({
    required this.recoveryKey,
    required this.supportsSecureStorage,
    this.storeInSecureStorage = false,
    this.recoveryKeyCopied = false,
  });

  BootstrapRecoveryKeyDisplayState copyWith({
    bool? storeInSecureStorage,
    bool? recoveryKeyCopied,
  }) => BootstrapRecoveryKeyDisplayState(
    recoveryKey: recoveryKey,
    supportsSecureStorage: supportsSecureStorage,
    storeInSecureStorage: storeInSecureStorage ?? this.storeInSecureStorage,
    recoveryKeyCopied: recoveryKeyCopied ?? this.recoveryKeyCopied,
  );

  @override
  List<Object?> get props => [
    recoveryKey,
    supportsSecureStorage,
    storeInSecureStorage,
    recoveryKeyCopied,
  ];
}

class BootstrapVerifyDeviceState extends BootstrapUiState {
  final String? prefilledRecoveryKey;
  final bool retrySucceeded;
  final bool retryFailed;

  const BootstrapVerifyDeviceState({
    this.prefilledRecoveryKey,
    this.retrySucceeded = false,
    this.retryFailed = false,
  });

  @override
  List<Object?> get props => [
    prefilledRecoveryKey,
    retrySucceeded,
    retryFailed,
  ];
}

class BootstrapLegacyErrorState extends BootstrapUiState {
  const BootstrapLegacyErrorState();
}

class BootstrapLegacyDoneState extends BootstrapUiState {
  const BootstrapLegacyDoneState();
}
