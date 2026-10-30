import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/providers/account_switch_coordinator.dart';

part 'account_switch_effects_provider.g.dart';

/// The effects the coordinator runs. `MatrixState` sets them after its first
/// frame and clears them in `dispose`; null while no `MatrixState` is mounted.
@Riverpod(keepAlive: true)
class AccountSwitchEffectsHolder extends _$AccountSwitchEffectsHolder {
  @override
  AccountSwitchEffects? build() => null;

  void set(AccountSwitchEffects effects) => state = effects;

  /// Clears [effects] only when they are still the ones set. Does nothing
  /// once the container is disposed: `MatrixState.dispose` can run after it.
  void clear(AccountSwitchEffects effects) {
    if (ref.mounted && identical(state, effects)) state = null;
  }
}
