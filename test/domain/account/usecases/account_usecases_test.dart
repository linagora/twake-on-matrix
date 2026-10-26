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
import 'package:twake_chat/domain/account/usecases/add_account.dart';
import 'package:twake_chat/domain/account/usecases/initialize_accounts.dart';
import 'package:twake_chat/domain/account/usecases/record_pending_removal.dart';
import 'package:twake_chat/domain/account/usecases/remove_account.dart';

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

class _FakeRepository extends Fake implements AccountRepository {
  _FakeRepository(this.registered);

  final List<Account> registered;
  final List<String> writes = [];

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
  Future<void> markRemovalPending(String id) async => writes.add('pending $id');
}

void main() {
  final a = _in('a');
  final b = _in('b');

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
      useCase = AddAccountUseCase(
        repository: repository,
        transitions: _transitions,
      );
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
      final next = await useCase.execute(
        () => Active(accounts: [a, b], activeId: 'a'),
        'b',
      );

      expect(next, isNull);
      expect(repository.writes, isEmpty);
    });

    test('stores nothing when the transition is invalid', () async {
      await expectLater(
        useCase.execute(() => const Booting(), 'b'),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
      expect(repository.writes, isEmpty);
    });

    test('keeps the state that is current after the write', () async {
      AccountsState current = Active(accounts: [a], activeId: 'a');
      repository = _FakeRepository([a, b, _in('c')])
        ..onWrite = () =>
            current = Active(accounts: [a, _in('c')], activeId: 'a');
      useCase = AddAccountUseCase(
        repository: repository,
        transitions: _transitions,
      );

      final next = await useCase.execute(() => current, 'b');

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
      useCase = RemoveAccountUseCase(
        repository: repository,
        transitions: _transitions,
      );
    });

    test('deletes the account and activates the next one', () async {
      final next = await useCase.execute(
        () => Active(accounts: [a, b], activeId: 'a'),
        'a',
      );

      expect(next, Active(accounts: [b], activeId: 'b'));
      expect(repository.writes, ['remove a']);
    });

    test('deletes nothing when the transition is invalid', () async {
      await expectLater(
        useCase.execute(() => const Booting(), 'a'),
        throwsA(isA<UnknownAccountException>()),
      );
      expect(repository.writes, isEmpty);
    });

    test('keeps the state that is current after the delete', () async {
      final c = _in('c');
      AccountsState current = Active(accounts: [a, b], activeId: 'a');
      repository = _FakeRepository([a, b, c])
        ..onWrite = () => current = Active(accounts: [a, b, c], activeId: 'a');
      useCase = RemoveAccountUseCase(
        repository: repository,
        transitions: _transitions,
      );

      final next = await useCase.execute(() => current, 'b');

      expect(next, Active(accounts: [a, c], activeId: 'a'));
    });
  });

  test('RecordPendingRemovalUseCase records the removal', () async {
    final repository = _FakeRepository([a]);

    await RecordPendingRemovalUseCase(repository: repository).execute('a');

    expect(repository.writes, ['pending a']);
  });
}
