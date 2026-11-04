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
import 'package:twake_chat/domain/account/repositories/account_repository.dart';
import 'package:twake_chat/domain/account/usecases/add_account_usecase.dart';
import 'package:twake_chat/domain/account/usecases/create_account_candidate_usecase.dart';
import 'package:twake_chat/domain/account/usecases/initialize_accounts_usecase.dart';
import 'package:twake_chat/domain/account/usecases/remove_account_usecase.dart';

const _policy = AccountPolicy();
const _support = AccountTransitionSupport();
const _transitions = AccountTransitions(
  init: AccountInitTransitions(_policy, _support),
  switching: AccountSwitchTransitions(_support),
  removal: AccountRemovalTransitions(_policy, _support),
  support: _support,
);

Account _in(String id) =>
    Account(id: id, userId: '@$id:s', status: AccountStatus.loggedIn);

Future<void> _expectRejected(
  Future<Object?> Function() run,
  Matcher matcher,
  _FakeRepository repository,
) async {
  await expectLater(run(), throwsA(matcher));
  expect(repository.writes, isEmpty);
}

class _FakeRepository extends Fake implements AccountRepository {
  _FakeRepository(this.registered);

  final List<Account> registered;
  final List<String> writes = [];
  final candidate = const Account(id: 'new', status: AccountStatus.loggedOut);

  /// Runs during a write, to change the state the use case reads after it.
  void Function()? onWrite;

  @override
  List<Account> registeredAccounts() => registered;

  @override
  Account accountOf(String id) => registered.firstWhere((a) => a.id == id);

  @override
  Future<void> addAccount(Account account) async {
    writes.add('add ${account.id}');
    onWrite?.call();
  }

  @override
  Future<void> removeAccount(String id) async {
    writes.add('remove $id');
    onWrite?.call();
  }

  @override
  Future<Account> createCandidate() async => candidate;

  @override
  Future<void> markRemovalPending(String id) async => writes.add('pending $id');
}

/// Runs [execute] with a state that [changed] replaces during the write.
Future<AccountsState?> _executeWithChangeDuringWrite(
  _FakeRepository repository,
  AccountsState start,
  AccountsState changed,
  Future<AccountsState?> Function(AccountsState Function() read) execute,
) {
  var current = start;
  repository.onWrite = () => current = changed;
  return execute(() => current);
}

AddAccountUseCase _addUseCase(_FakeRepository repository) =>
    AddAccountUseCase(repository: repository, transitions: _transitions);

RemoveAccountUseCase _removeUseCase(_FakeRepository repository) =>
    RemoveAccountUseCase(repository: repository, transitions: _transitions);

void main() {
  final a = _in('a');
  final b = _in('b');
  AccountsState activeAB() => Active(accounts: [a, b], activeId: 'a');

  test('InitializeAccountsUseCase starts on the persisted account', () {
    final useCase = InitializeAccountsUseCase(
      repository: _FakeRepository([a, b]),
      transitions: _transitions,
    );

    expect(
      useCase.execute(persistedUserId: '@b:s'),
      Active(accounts: [a, b], activeId: 'b'),
    );
  });

  group('AddAccountUseCase', () {
    late _FakeRepository repository;
    late AddAccountUseCase useCase;

    setUp(() {
      repository = _FakeRepository([a, b]);
      useCase = _addUseCase(repository);
    });

    test('stores the account and lists it', () async {
      final next = await useCase.execute(
        () => Active(accounts: [a], activeId: 'a'),
        'b',
      );

      expect(next, Active(accounts: [a, b], activeId: 'a'));
      expect(repository.writes, ['add b']);
    });

    test('does nothing for an account that is already listed', () async {
      final next = await useCase.execute(activeAB, 'b');

      expect(next, isNull);
      expect(repository.writes, isEmpty);
    });

    test('stores nothing when the transition is invalid', () {
      return _expectRejected(
        () => useCase.execute(() => const Booting(), 'b'),
        isA<InvalidAccountTransitionException>(),
        repository,
      );
    });

    test('keeps the state that is current after the write', () async {
      repository.registered.add(_in('c'));

      final next = await _executeWithChangeDuringWrite(
        repository,
        Active(accounts: [a], activeId: 'a'),
        Active(accounts: [a, _in('c')], activeId: 'a'),
        (read) => useCase.execute(read, 'b'),
      );

      expect(next, Active(accounts: [a, _in('c'), b], activeId: 'a'));
    });

    test('does nothing for an account listed while a switch runs', () async {
      final next = await useCase.execute(
        () => Switching(accounts: [a, b], from: 'a', to: 'b', seq: 1),
        'b',
      );

      expect(next, isNull);
      expect(repository.writes, isEmpty);
    });
  });

  group('RemoveAccountUseCase', () {
    late _FakeRepository repository;
    late RemoveAccountUseCase useCase;

    setUp(() {
      repository = _FakeRepository([a, b]);
      useCase = _removeUseCase(repository);
    });

    test('deletes the account and activates the next one', () async {
      final next = await useCase.execute(activeAB, 'a');

      expect(next, Active(accounts: [b], activeId: 'b'));
      expect(repository.writes, ['remove a']);
    });

    test('deletes nothing when the transition is invalid', () {
      return _expectRejected(
        () => useCase.execute(() => const Booting(), 'a'),
        isA<UnknownAccountException>(),
        repository,
      );
    });

    test('keeps the state that is current after the delete', () async {
      final c = _in('c');
      repository.registered.add(c);

      final next = await _executeWithChangeDuringWrite(
        repository,
        activeAB(),
        Active(accounts: [a, b, c], activeId: 'a'),
        (read) => useCase.execute(read, 'b'),
      );

      expect(next, Active(accounts: [a, c], activeId: 'a'));
    });
  });

  test('CreateAccountCandidateUseCase returns the new candidate', () async {
    final repository = _FakeRepository([a]);

    expect(
      await CreateAccountCandidateUseCase(repository: repository).execute(),
      repository.candidate,
    );
  });
}
