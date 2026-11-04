import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/policy/account_init_transitions.dart';
import 'package:twake_chat/domain/account/policy/account_policy.provider.dart';
import 'package:twake_chat/domain/account/policy/account_removal_transitions.dart';
import 'package:twake_chat/domain/account/policy/account_switch_transitions.dart';
import 'package:twake_chat/domain/account/policy/account_transition_support.dart';
import 'package:twake_chat/domain/account/policy/account_transitions.dart';

part 'account_transitions.provider.g.dart';

// Kept alive: read by the session-wide accountsProvider and the account use cases, and a kept-alive
// provider cannot depend on an auto-dispose one.
@Riverpod(keepAlive: true)
AccountTransitions accountTransitions(Ref ref) {
  final policy = ref.watch(accountPolicyProvider);
  const support = AccountTransitionSupport();
  return AccountTransitions(
    init: AccountInitTransitions(policy, support),
    switching: const AccountSwitchTransitions(support),
    removal: AccountRemovalTransitions(policy, support),
    support: support,
  );
}
