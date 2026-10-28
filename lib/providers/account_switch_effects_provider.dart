import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/providers/account_switch_coordinator.dart';

/// The effects the coordinator runs. `MatrixState` sets them in `initState`
/// and clears them in `dispose`; null while no `MatrixState` is mounted.
final accountSwitchEffectsProvider =
    NotifierProvider<AccountSwitchEffectsHolder, AccountSwitchEffects?>(
      AccountSwitchEffectsHolder.new,
    );

class AccountSwitchEffectsHolder extends Notifier<AccountSwitchEffects?> {
  @override
  AccountSwitchEffects? build() => null;

  void set(AccountSwitchEffects effects) => state = effects;

  /// Clears [effects] only when they are still the ones set.
  void clear(AccountSwitchEffects effects) {
    if (identical(state, effects)) state = null;
  }
}
