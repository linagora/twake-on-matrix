import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/policy/account_init_transitions.dart';
import 'package:twake_chat/domain/account/policy/account_policy.dart';
import 'package:twake_chat/domain/account/policy/account_removal_transitions.dart';
import 'package:twake_chat/domain/account/policy/account_switch_transitions.dart';
import 'package:twake_chat/domain/account/policy/account_transition_support.dart';
import 'package:twake_chat/domain/account/policy/account_transitions.dart';

const accountPolicy = AccountPolicy();
const accountSupport = AccountTransitionSupport();
const accountTransitions = AccountTransitions(
  init: AccountInitTransitions(accountPolicy, accountSupport),
  switching: AccountSwitchTransitions(accountSupport),
  removal: AccountRemovalTransitions(accountPolicy, accountSupport),
  support: accountSupport,
);

Account accountWith(String id, AccountStatus status) => Account(
  id: id,
  status: status,
  userId: status == AccountStatus.loggedIn ? '@$id:server' : null,
);
