import 'package:freezed_annotation/freezed_annotation.dart';

part 'tom_bootstrap_state.freezed.dart';

/// UI-shape state for `TomBootstrapDialog` — mirrors `BootstrapUiState`'s
/// role for `BootstrapDialog`, but additionally tracks the TOM recovery-vault
/// round-trip (`UploadRecoveryKeyState` in the original `StatefulWidget`)
/// alongside the `matrix` SDK `Bootstrap` state machine, since the two are
/// interleaved here.
///
/// [popTick] carries the terminal outcome the widget should act on
/// (`Navigator.pop`/snackbar/`showToMBootstrap`). It's bumped on every
/// terminal `_refresh` call (even when the resulting state instance would
/// otherwise compare equal to the previous one via freezed's generated
/// `==`) so `ref.listen` always sees a change and never misses a pop.
@freezed
sealed class TomBootstrapUiState with _$TomBootstrapUiState {
  /// Waiting on `client.firstSyncReceived`/`userDeviceKeysLoading`/
  /// `roomsLoading`/`accountDataLoading`, or a `matrix` SDK auto-driven
  /// `BootstrapState` transition — both render the same spinner.
  const factory TomBootstrapUiState.loading({@Default(0) int popTick}) =
      TomBootstrapLoadingState;

  const factory TomBootstrapUiState.checkingRecovery({
    @Default(0) int popTick,
  }) = TomBootstrapCheckingRecoveryState;

  const factory TomBootstrapUiState.uploadingCrossSigningKeys({
    @Default(0) int popTick,
  }) = TomBootstrapUploadingCrossSigningKeysState;

  /// No recovery words to fall back on and no `Bootstrap` was even started —
  /// stays on the spinner (no error UI, matching the original) until
  /// `TomBootstrapViewModel.noRecoveryWordsCloseDelay` elapses and closes
  /// itself with `popValue == false`.
  const factory TomBootstrapUiState.noRecoveryWords({
    @Default(0) int popTick,
    bool? popValue,
  }) = TomBootstrapNoRecoveryWordsState;

  const factory TomBootstrapUiState.wipeRecoveryFailed({
    @Default(0) int popTick,
  }) = TomBootstrapWipeRecoveryFailedState;

  const factory TomBootstrapUiState.unlockError({@Default(0) int popTick}) =
      TomBootstrapUnlockErrorState;

  const factory TomBootstrapUiState.uploadError({@Default(0) int popTick}) =
      TomBootstrapUploadErrorState;

  const factory TomBootstrapUiState.error({@Default(0) int popTick}) =
      TomBootstrapErrorState;

  const factory TomBootstrapUiState.done({@Default(0) int popTick}) =
      TomBootstrapDoneState;
}

extension TomBootstrapUiStateX on TomBootstrapUiState {
  /// `null` while non-terminal; the value `Navigator.pop<bool>` should use
  /// once terminal (`popTrue`/`popFalse` map to `true`/`false`, `popNull`
  /// maps to `null` itself — [isTerminal] disambiguates "not terminal yet"
  /// from "terminal with a null pop value").
  bool? get popValue => switch (this) {
    TomBootstrapNoRecoveryWordsState(:final popValue) => popValue,
    TomBootstrapUnlockErrorState() => false,
    TomBootstrapDoneState() => true,
    TomBootstrapWipeRecoveryFailedState() ||
    TomBootstrapUploadErrorState() ||
    TomBootstrapErrorState() => null,
    TomBootstrapLoadingState() ||
    TomBootstrapCheckingRecoveryState() ||
    TomBootstrapUploadingCrossSigningKeysState() => null,
  };

  bool get isTerminal => switch (this) {
    TomBootstrapNoRecoveryWordsState(:final popValue) => popValue != null,
    TomBootstrapWipeRecoveryFailedState() ||
    TomBootstrapUnlockErrorState() ||
    TomBootstrapUploadErrorState() ||
    TomBootstrapErrorState() ||
    TomBootstrapDoneState() => true,
    TomBootstrapLoadingState() ||
    TomBootstrapCheckingRecoveryState() ||
    TomBootstrapUploadingCrossSigningKeysState() => false,
  };
}
