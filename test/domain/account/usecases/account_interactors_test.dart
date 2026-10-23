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
import 'package:twake_chat/domain/account/usecases/add_account_interactor.dart';
import 'package:twake_chat/domain/account/usecases/create_account_candidate_interactor.dart';
import 'package:twake_chat/domain/account/usecases/initialize_accounts_interactor.dart';
import 'package:twake_chat/domain/account/usecases/record_pending_removal_interactor.dart';
import 'package:twake_chat/domain/account/usecases/remove_account_interactor.dart';

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
  final candidate = const Account(id: 'new', status: AccountStatus.loggedOut);

  @override
  List<Account> registeredAccounts() => registered;

  @override
  Account accountOf(String id) => registered.firstWhere((a) => a.id == id);

  @override
  Future<void> addAccount(Account account) async =>
      writes.add('add ${account.id}');

  @override
  Future<void> removeAccount(String id) async => writes.add('remove $id');

  @override
  Future<Account> createCandidate() async => candidate;

  @override
  Future<void> markRemovalPending(String id) async => writes.add('pending $id');
}

void main() {
  final a = _in('a');
  final b = _in('b');

  test('InitializeAccountsInteractor starts on the persisted account', () {
    final interactor = InitializeAccountsInteractor(
      repository: _FakeRepository([a, b]),
      transitions: _transitions,
    );

    expect(
      interactor.execute(persistedUserId: '@b:s'),
      Active(accounts: [a, b], activeId: 'b'),
    );
  });

  group('AddAccountInteractor', () {
    late _FakeRepository repository;
    late AddAccountInteractor interactor;

    setUp(() {
      repository = _FakeRepository([a, b]);
      interactor = AddAccountInteractor(
        repository: repository,
        transitions: _transitions,
      );
    });

    test('stores the account and lists it', () async {
      final next = await interactor.execute(
        () => Active(accounts: [a], activeId: 'a'),
        'b',
      );

      expect(next, Active(accounts: [a, b], activeId: 'a'));
      expect(repository.writes, ['add b']);
    });

    test('does nothing for an account that is already listed', () async {
      final next = await interactor.execute(
        () => Active(accounts: [a, b], activeId: 'a'),
        'b',
      );

      expect(next, isNull);
      expect(repository.writes, isEmpty);
    });

    test('stores nothing when the transition is invalid', () async {
      await expectLater(
        interactor.execute(() => const Booting(), 'b'),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
      expect(repository.writes, isEmpty);
    });
  });

  group('RemoveAccountInteractor', () {
    late _FakeRepository repository;
    late RemoveAccountInteractor interactor;

    setUp(() {
      repository = _FakeRepository([a, b]);
      interactor = RemoveAccountInteractor(
        repository: repository,
        transitions: _transitions,
      );
    });

    test('deletes the account and activates the next one', () async {
      final next = await interactor.execute(
        () => Active(accounts: [a, b], activeId: 'a'),
        'a',
      );

      expect(next, Active(accounts: [b], activeId: 'b'));
      expect(repository.writes, ['remove a']);
    });

    test('deletes nothing when the transition is invalid', () async {
      await expectLater(
        interactor.execute(() => const Booting(), 'a'),
        throwsA(isA<UnknownAccountException>()),
      );
      expect(repository.writes, isEmpty);
    });
  });

  test('RecordPendingRemovalInteractor records the removal', () async {
    final repository = _FakeRepository([a]);

    await RecordPendingRemovalInteractor(repository: repository).execute('a');

    expect(repository.writes, ['pending a']);
  });

  test('CreateAccountCandidateInteractor returns the new candidate', () async {
    final repository = _FakeRepository([a]);

    expect(
      await CreateAccountCandidateInteractor(repository: repository).execute(),
      repository.candidate,
    );
  });
}
