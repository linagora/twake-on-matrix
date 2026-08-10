import 'package:equatable/equatable.dart';

/// UI-shape state for `TomBootstrapDialog` — mirrors `BootstrapUiState`'s
/// role for `BootstrapDialog`, but additionally tracks the TOM recovery-vault
/// round-trip (`UploadRecoveryKeyState` in the original `StatefulWidget`)
/// alongside the `matrix` SDK `Bootstrap` state machine, since the two are
/// interleaved here.
///
/// [popTick] carries the terminal outcome the widget should act on
/// (`Navigator.pop`/snackbar/`showToMBootstrap`). It's bumped on every
/// terminal `_refresh` call (even when the resulting state instance would
/// otherwise compare equal to the previous one via [Equatable]) so
/// `ref.listen` always sees a change and never misses a pop.
sealed class TomBootstrapUiState extends Equatable {
  final int popTick;

  const TomBootstrapUiState({this.popTick = 0});

  /// `null` while non-terminal; the value `Navigator.pop<bool>` should use
  /// once terminal (`popTrue`/`popFalse` map to `true`/`false`, `popNull`
  /// maps to `null` itself — [isTerminal] disambiguates "not terminal yet"
  /// from "terminal with a null pop value").
  bool? get popValue => null;

  bool get isTerminal => false;

  @override
  List<Object?> get props => [popTick];
}

/// Waiting on `client.firstSyncReceived`/`userDeviceKeysLoading`/
/// `roomsLoading`/`accountDataLoading`, or a `matrix` SDK auto-driven
/// `BootstrapState` transition — both render the same spinner.
class TomBootstrapLoadingState extends TomBootstrapUiState {
  const TomBootstrapLoadingState({super.popTick});
}

class TomBootstrapCheckingRecoveryState extends TomBootstrapUiState {
  const TomBootstrapCheckingRecoveryState({super.popTick});
}

class TomBootstrapUploadingCrossSigningKeysState extends TomBootstrapUiState {
  const TomBootstrapUploadingCrossSigningKeysState({super.popTick});
}

/// No recovery words to fall back on and no `Bootstrap` was even started —
/// stays on the spinner (no error UI, matching the original) until
/// `TomBootstrapViewModel.noRecoveryWordsCloseDelay` elapses and closes
/// itself with `popValue == false`.
class TomBootstrapNoRecoveryWordsState extends TomBootstrapUiState {
  @override
  final bool? popValue;

  const TomBootstrapNoRecoveryWordsState({super.popTick, this.popValue});

  @override
  bool get isTerminal => popValue != null;

  @override
  List<Object?> get props => [...super.props, popValue];
}

class TomBootstrapWipeRecoveryFailedState extends TomBootstrapUiState {
  const TomBootstrapWipeRecoveryFailedState({super.popTick});

  @override
  bool? get popValue => null;

  @override
  bool get isTerminal => true;
}

class TomBootstrapUnlockErrorState extends TomBootstrapUiState {
  const TomBootstrapUnlockErrorState({super.popTick});

  @override
  bool? get popValue => false;

  @override
  bool get isTerminal => true;
}

class TomBootstrapUploadErrorState extends TomBootstrapUiState {
  const TomBootstrapUploadErrorState({super.popTick});

  @override
  bool? get popValue => null;

  @override
  bool get isTerminal => true;
}

class TomBootstrapErrorState extends TomBootstrapUiState {
  const TomBootstrapErrorState({super.popTick});

  @override
  bool? get popValue => null;

  @override
  bool get isTerminal => true;
}

class TomBootstrapDoneState extends TomBootstrapUiState {
  const TomBootstrapDoneState({super.popTick});

  @override
  bool? get popValue => true;

  @override
  bool get isTerminal => true;
}
