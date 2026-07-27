import 'package:equatable/equatable.dart';
import 'package:matrix/encryption.dart';

/// UI-shape state for `VerifyDeviceScreen` — the chooser plus every
/// sub-flow it can show (SAS verification, recovery-key form,
/// reset-encryption, and the caller's own "Retry automatically" outcome).
sealed class VerifyDeviceUiState extends Equatable {
  const VerifyDeviceUiState();

  @override
  List<Object?> get props => [];
}

class VerifyDeviceChooserState extends VerifyDeviceUiState {
  final bool isStartingVerification;

  const VerifyDeviceChooserState({this.isStartingVerification = false});

  @override
  List<Object?> get props => [isStartingVerification];
}

/// Mirrors `KeyVerificationState` while a SAS request from "Use another
/// device" is in flight.
///
/// [requestState] is captured once at construction time — [request] itself
/// is a live, mutable SDK object whose `.state` keeps changing after this
/// object is built, so comparing two [VerifyDeviceSasState]s by reading
/// `request.state` live (rather than a frozen copy) always sees the same,
/// already-mutated value on both sides and never detects a change.
class VerifyDeviceSasState extends VerifyDeviceUiState {
  final KeyVerification request;
  final KeyVerificationState requestState;

  VerifyDeviceSasState({required this.request}) : requestState = request.state;

  @override
  List<Object?> get props => [requestState];
}

class VerifyDeviceRecoveryKeyFormState extends VerifyDeviceUiState {
  final String? initialValue;
  final String? errorText;

  const VerifyDeviceRecoveryKeyFormState({this.initialValue, this.errorText});

  @override
  List<Object?> get props => [initialValue, errorText];
}

class VerifyDeviceResetConfirmState extends VerifyDeviceUiState {
  final bool isResetting;

  const VerifyDeviceResetConfirmState({this.isResetting = false});

  @override
  List<Object?> get props => [isResetting];
}

class VerifyDeviceResetCompleteState extends VerifyDeviceUiState {
  const VerifyDeviceResetCompleteState();
}

class VerifyDeviceSuccessState extends VerifyDeviceUiState {
  const VerifyDeviceSuccessState();
}

/// Failure surfaced from the caller's own "Retry automatically" flow —
/// distinct from `VerifyDeviceSasState`'s `KeyVerificationState.error`,
/// since retry never ran the SAS sub-flow at all.
class VerifyDeviceRetryErrorState extends VerifyDeviceUiState {
  const VerifyDeviceRetryErrorState();
}
