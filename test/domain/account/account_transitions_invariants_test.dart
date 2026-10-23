import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/account/policy/account_init_transitions.dart';
import 'package:twake_chat/domain/account/policy/account_policy.dart';
import 'package:twake_chat/domain/account/policy/account_removal_transitions.dart';
import 'package:twake_chat/domain/account/policy/account_switch_transitions.dart';
import 'package:twake_chat/domain/account/policy/account_transition_support.dart';
import 'package:twake_chat/domain/account/policy/account_transitions.dart';

const _policy = AccountPolicy();
const _support = AccountTransitionSupport();
const _transitions = AccountTransitions(
  init: AccountInitTransitions(_policy, _support),
  switching: AccountSwitchTransitions(_support),
  removal: AccountRemovalTransitions(_policy, _support),
  support: _support,
);

const _ids = ['a', 'b', 'c'];
const _probeIds = ['a', 'b', 'c', 'x'];

Account _account(String id, AccountStatus status) => Account(
  id: id,
  status: status,
  userId: status == AccountStatus.loggedIn ? '@$id:server' : null,
);

/// Every subset of [_ids], in order, each member in every status.
List<List<Account>> _accountLists() {
  var lists = <List<Account>>[[]];
  for (final id in _ids) {
    lists = [
      for (final list in lists) ...[
        list,
        for (final status in AccountStatus.values)
          [...list, _account(id, status)],
      ],
    ];
  }
  return lists;
}

bool _isLoggedIn(List<Account> accounts, String id) =>
    accounts.any((a) => a.id == id && a.isLoggedIn);

List<String> _duplicateIds(List<Account> accounts) {
  final ids = accounts.map((a) => a.id).toList();
  return [if (ids.toSet().length != ids.length) 'duplicate ids $ids'];
}

List<String> _activeViolations(Active state) => [
  if (!_isLoggedIn(state.accounts, state.activeId))
    'active ${state.activeId} is not a logged-in account',
];

List<String> _switchingViolations(Switching state) => [
  if (!_isLoggedIn(state.accounts, state.from))
    'from ${state.from} is not logged in',
  if (!_isLoggedIn(state.accounts, state.to)) 'to ${state.to} is not logged in',
  if (state.from == state.to) 'switch from ${state.from} to itself',
];

List<String> _noAccountViolations(NoAccount state) => [
  if (state.accounts.any((a) => a.status != AccountStatus.unavailable))
    'NoAccount lists an account that is not unavailable',
  if (state.accounts.any((a) => a.id == state.candidateId))
    'candidate ${state.candidateId} is also listed',
];

List<String> _lastLoggedOutViolations(LastLoggedOut state) => [
  if (state.account.status != AccountStatus.loggedOut)
    'LastLoggedOut holds ${state.account.status}',
];

/// What a state must always satisfy, whatever transition produced it.
List<String> _violations(AccountsState state) => [
  ..._duplicateIds(state.accounts),
  ...switch (state) {
    Active() => _activeViolations(state),
    Switching() => _switchingViolations(state),
    NoAccount() => _noAccountViolations(state),
    LastLoggedOut() => _lastLoggedOutViolations(state),
    Booting() => const <String>[],
  },
];

List<AccountsState> _validStates() {
  final states = <AccountsState>[
    const Booting(),
    LastLoggedOut(account: _account('a', AccountStatus.loggedOut)),
  ];
  for (final list in _accountLists()) {
    final loggedIn = [
      for (final a in list)
        if (a.isLoggedIn) a.id,
    ];
    states.addAll([
      NoAccount(accounts: list),
      NoAccount(candidateId: 'x', accounts: list),
      for (final id in loggedIn) Active(accounts: list, activeId: id),
      for (final from in loggedIn)
        for (final to in loggedIn)
          if (from != to) Switching(accounts: list, from: from, to: to, seq: 1),
    ]);
  }
  return states.where((s) => _violations(s).isEmpty).toList();
}

class _Expect {
  const _Expect({
    this.candidates = const {},
    this.removedId,
    this.superseded = false,
  });

  /// The ids a [NoAccount] result may offer as the next login's placeholder.
  final Set<String> candidates;
  final String? removedId;

  /// A settlement with another number than the running switch's.
  final bool superseded;
}

class _Case {
  const _Case(this.label, this.run, this.expect);

  final String label;
  final AccountsState Function() run;
  final _Expect expect;
}

Set<String> _candidatesFrom(AccountsState before) => {
  for (final a in before.accounts)
    if (a.status == AccountStatus.loggedOut) a.id,
  if (before case NoAccount(:final candidateId?)) candidateId,
  if (before case Active(:final activeId)) activeId,
};

Iterable<_Case> _initializeCases() sync* {
  for (final list in _accountLists()) {
    for (final persisted in [null, '@b:server']) {
      yield _Case(
        'initialize(${list.map((a) => '${a.id}:${a.status.name}')}, $persisted)',
        () => _transitions.initialize(
          const Booting(),
          list,
          persistedUserId: persisted,
        ),
        _Expect(candidates: _candidatesFrom(NoAccount(accounts: list))),
      );
    }
  }
}

Iterable<_Case> _settleCases(AccountsState s) sync* {
  final running = s is Switching ? s.seq : 1;
  for (final seq in [running, running + 1]) {
    final stale = s is Switching && seq != running;
    final expect = _Expect(superseded: stale);
    yield _Case(
      'completeSwitch($seq)',
      () => _transitions.completeSwitch(s, seq),
      expect,
    );
    yield _Case(
      'failSwitch($seq)',
      () => _transitions.failSwitch(s, seq),
      expect,
    );
  }
}

Iterable<_Case> _idCases(AccountsState s, String id) sync* {
  final expect = _Expect(candidates: _candidatesFrom(s));
  final seq = s is Switching ? s.seq + 1 : 1;
  yield _Case(
    'add($id)',
    () => _transitions.add(s, _account(id, AccountStatus.loggedIn)),
    expect,
  );
  yield _Case(
    'add($id loggedOut)',
    () => _transitions.add(s, _account(id, AccountStatus.loggedOut)),
    expect,
  );
  yield _Case(
    'beginSwitch($id)',
    () => _transitions.beginSwitch(s, id, seq: seq),
    expect,
  );
  yield _Case(
    'remove($id)',
    () => _transitions.remove(s, id),
    _Expect(candidates: expect.candidates, removedId: id),
  );
  yield _Case(
    'markUnavailable($id)',
    () => _transitions.markUnavailable(s, id),
    expect,
  );
}

Iterable<_Case> _transitionCases(AccountsState s) sync* {
  yield _Case(
    'initialize(a)',
    () => _transitions.initialize(s, [_account('a', AccountStatus.loggedIn)]),
    const _Expect(),
  );
  yield _Case(
    'logoutLast',
    () => _transitions.logoutLast(s),
    _Expect(candidates: _candidatesFrom(s)),
  );
  yield* _settleCases(s);
  for (final id in _probeIds) {
    yield* _idCases(s, id);
  }
}

List<String> _resultProblems(AccountsState result, _Expect expect) => [
  ..._violations(result),
  if (result case NoAccount(
    :final candidateId?,
  ) when !expect.candidates.contains(candidateId))
    'candidate $candidateId is not a logged-out account',
  if (expect.removedId != null &&
      (result.accounts.any((a) => a.id == expect.removedId) ||
          (result is NoAccount && result.candidateId == expect.removedId)))
    '${expect.removedId} is still there after remove',
];

List<String> _problems(_Case c) {
  final AccountsState result;
  try {
    result = c.run();
  } on AccountException catch (e) {
    return c.expect.superseded && e is! SwitchSupersededException
        ? ['stale settle threw ${e.runtimeType}, not SwitchSuperseded']
        : const [];
  } catch (e) {
    return ['untyped ${e.runtimeType}: $e'];
  }
  if (c.expect.superseded) return ['stale settle was accepted'];
  return _resultProblems(result, c.expect);
}

List<String> _allProblems() {
  final cases = [
    ..._initializeCases(),
    for (final state in _validStates())
      ..._transitionCases(
        state,
      ).map((c) => _Case('${c.label} from $state', c.run, c.expect)),
  ];
  return [
    for (final c in cases)
      for (final problem in _problems(c)) '${c.label}: $problem',
  ];
}

void main() {
  test('every transition from a valid state gives a valid state or a typed '
      'exception', () {
    final problems = _allProblems();
    expect(
      problems,
      isEmpty,
      reason:
          '${problems.length} problems, first:\n'
          '${problems.take(12).join('\n')}',
    );
  });
}
