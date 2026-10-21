import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/account/policy/account_transitions.dart';
import 'package:flutter_test/flutter_test.dart';

Account _in(String id) =>
    Account(id: id, userId: '@$id:server', status: AccountStatus.loggedIn);

Account _out(String id) => Account(id: id, status: AccountStatus.loggedOut);

Account _failed(String id, Object error) =>
    Account(id: id, status: AccountStatus.initFailed, initError: error);

Account _waiting(String id) =>
    Account(id: id, status: AccountStatus.unavailable);

void main() {
  final a = _in('a');
  final b = _in('b');
  final c = _in('c');

  group('initialize', () {
    test('logged-out boot with a placeholder gives NoAccount(candidate)', () {
      expect(
        AccountTransitions.initialize(const Booting(), [_out('p')]),
        const NoAccount(candidateId: 'p'),
      );
    });

    test('logged-out boot with an empty list gives NoAccount(null)', () {
      expect(
        AccountTransitions.initialize(const Booting(), []),
        const NoAccount(),
      );
    });

    test('persisted account present becomes active', () {
      expect(
        AccountTransitions.initialize(const Booting(), [
          a,
          b,
        ], persistedUserId: '@b:server'),
        Active(accounts: [a, b], activeId: 'b'),
      );
    });

    test('persisted account missing falls back to the first logged-in', () {
      expect(
        AccountTransitions.initialize(const Booting(), [a, b]),
        Active(accounts: [a, b], activeId: 'a'),
      );
    });

    test('persisted account unknown falls back to the first logged-in', () {
      expect(
        AccountTransitions.initialize(const Booting(), [
          a,
          b,
        ], persistedUserId: '@zzz:server'),
        Active(accounts: [a, b], activeId: 'a'),
      );
    });

    test('a logged-out account is skipped as initial active', () {
      expect(
        AccountTransitions.initialize(const Booting(), [_out('x'), b]),
        Active(accounts: [_out('x'), b], activeId: 'b'),
      );
    });

    test('only init-failed accounts give AccountInitFailed for the first', () {
      final error = StateError('boom');
      expect(
        AccountTransitions.initialize(const Booting(), [
          _failed('f1', error),
          _failed('f2', 'other'),
        ]),
        AccountInitFailed(id: 'f1', error: error),
      );
    });

    test('AccountInitFailed keeps the accounts that wait for removal', () {
      final error = StateError('boom');
      expect(
        AccountTransitions.initialize(const Booting(), [
          _failed('f', error),
          _waiting('w'),
        ]),
        AccountInitFailed(id: 'f', error: error, accounts: [_waiting('w')]),
      );
    });

    test('a failed account does not hide the logged-out placeholder', () {
      expect(
        AccountTransitions.initialize(const Booting(), [
          _failed('f', 1),
          _out('x'),
          _waiting('w'),
        ]),
        NoAccount(candidateId: 'x', accounts: [_waiting('w')]),
      );
    });

    test('a logged-in account wins over an init-failed one', () {
      expect(
        AccountTransitions.initialize(const Booting(), [_failed('f', 1), a]),
        Active(accounts: [_failed('f', 1), a], activeId: 'a'),
      );
    });

    test('is rejected outside Booting', () {
      expect(
        () => AccountTransitions.initialize(const NoAccount(), [a]),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });
  });

  group('add', () {
    test('first login from NoAccount gives Active([a], a)', () {
      expect(
        AccountTransitions.add(const NoAccount(candidateId: 'p'), a),
        Active(accounts: [a], activeId: 'a'),
      );
    });

    test('add on Active appends and keeps the active account', () {
      expect(
        AccountTransitions.add(Active(accounts: [a], activeId: 'a'), b),
        Active(accounts: [a, b], activeId: 'a'),
      );
    });

    test('add then switch makes the new account active', () {
      var state = AccountTransitions.add(
        Active(accounts: [a], activeId: 'a'),
        b,
      );
      state = AccountTransitions.beginSwitch(state, 'b');
      expect(state, Switching(accounts: [a, b], from: 'a', to: 'b'));
      state = AccountTransitions.completeSwitch(state, 0);
      expect(state, Active(accounts: [a, b], activeId: 'b'));
    });

    test('login again after the last logout gives Active([a], a)', () {
      expect(
        AccountTransitions.add(LastLoggedOut(account: _out('a')), a),
        Active(accounts: [a], activeId: 'a'),
      );
    });

    test('a different account after the last logout is rejected', () {
      expect(
        () => AccountTransitions.add(LastLoggedOut(account: _out('a')), b),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });

    test('a duplicate id is rejected', () {
      expect(
        () => AccountTransitions.add(Active(accounts: [a], activeId: 'a'), a),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });

    test('an account that is not logged in is rejected', () {
      expect(
        () => AccountTransitions.add(const NoAccount(), _out('x')),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });

    test('is rejected while Booting or Switching', () {
      expect(
        () => AccountTransitions.add(const Booting(), a),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
      expect(
        () => AccountTransitions.add(
          Switching(accounts: [a, b], from: 'a', to: 'b'),
          c,
        ),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });
  });

  group('beginSwitch / completeSwitch / failSwitch', () {
    final active = Active(accounts: [a, b], activeId: 'a');

    test('switch goes through Switching then Active', () {
      final switching = AccountTransitions.beginSwitch(active, 'b');
      expect(switching, Switching(accounts: [a, b], from: 'a', to: 'b'));
      expect(
        AccountTransitions.completeSwitch(switching, 0),
        Active(accounts: [a, b], activeId: 'b'),
      );
    });

    test('switch to the active account is a no-op', () {
      expect(AccountTransitions.beginSwitch(active, 'a'), same(active));
    });

    test('switch to an unknown account throws', () {
      expect(
        () => AccountTransitions.beginSwitch(active, 'x'),
        throwsA(isA<UnknownAccountException>()),
      );
      expect(
        () => AccountTransitions.beginSwitch(const NoAccount(), 'x'),
        throwsA(isA<UnknownAccountException>()),
      );
    });

    test('a second switch supersedes the first and keeps the origin', () {
      final first = AccountTransitions.beginSwitch(
        Active(accounts: [a, b, c], activeId: 'a'),
        'b',
      );
      expect(
        AccountTransitions.beginSwitch(first, 'c'),
        Switching(accounts: [a, b, c], from: 'a', to: 'c'),
      );
    });

    test('switching back to the origin during a switch returns to Active', () {
      final first = AccountTransitions.beginSwitch(active, 'b');
      expect(AccountTransitions.beginSwitch(first, 'a'), active);
    });

    test('a stale handler cannot settle a newer switch', () {
      final first = AccountTransitions.beginSwitch(
        Active(accounts: [a, b, c], activeId: 'a'),
        'b',
        seq: 1,
      );
      final second = AccountTransitions.beginSwitch(first, 'c', seq: 2);
      for (final settle in [
        AccountTransitions.completeSwitch,
        AccountTransitions.failSwitch,
      ]) {
        expect(
          () => settle(second, 1),
          throwsA(
            isA<SwitchSupersededException>().having(
              (e) => e.accountId,
              'accountId',
              'c',
            ),
          ),
        );
      }
      expect(
        AccountTransitions.completeSwitch(second, 2),
        Active(accounts: [a, b, c], activeId: 'c'),
      );
    });

    test('a newer switch to the same target is also told apart', () {
      final first = AccountTransitions.beginSwitch(
        Active(accounts: [a, b, c], activeId: 'a'),
        'b',
        seq: 1,
      );
      final again = Switching(
        accounts: first.accounts,
        from: 'a',
        to: 'b',
        seq: 2,
      );
      expect(
        () => AccountTransitions.completeSwitch(again, 1),
        throwsA(isA<SwitchSupersededException>()),
      );
    });

    test('a failed switch returns to Active(from)', () {
      final switching = AccountTransitions.beginSwitch(active, 'b');
      expect(AccountTransitions.failSwitch(switching, 0), active);
    });

    test('complete and fail outside Switching are rejected', () {
      expect(
        () => AccountTransitions.completeSwitch(active, 0),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
      expect(
        () => AccountTransitions.failSwitch(active, 0),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });

    test('a logged-out or init-failed target is rejected', () {
      final state = Active(
        accounts: [a, _out('x'), _failed('f', 1)],
        activeId: 'a',
      );
      for (final id in ['x', 'f']) {
        expect(
          () => AccountTransitions.beginSwitch(state, id),
          throwsA(isA<InvalidAccountTransitionException>()),
        );
      }
    });

    test('a known account in a state that cannot switch is rejected', () {
      expect(
        () => AccountTransitions.beginSwitch(
          LastLoggedOut(account: _out('a')),
          'a',
        ),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });
  });

  group('remove', () {
    test('removing a non-active account keeps the active one (D4)', () {
      expect(
        AccountTransitions.remove(
          Active(accounts: [a, b, c], activeId: 'c'),
          'a',
        ),
        Active(accounts: [b, c], activeId: 'c'),
      );
    });

    test('removing the active account picks the follower (P2)', () {
      expect(
        AccountTransitions.remove(
          Active(accounts: [a, b, c], activeId: 'a'),
          'a',
        ),
        Active(accounts: [b, c], activeId: 'b'),
      );
    });

    test('removing the active last account picks the previous one', () {
      expect(
        AccountTransitions.remove(Active(accounts: [a, b], activeId: 'b'), 'b'),
        Active(accounts: [a], activeId: 'a'),
      );
    });

    test('removing an unknown account throws', () {
      expect(
        () => AccountTransitions.remove(
          Active(accounts: [a, b], activeId: 'a'),
          'x',
        ),
        throwsA(isA<UnknownAccountException>()),
      );
      expect(
        () => AccountTransitions.remove(const Booting(), 'x'),
        throwsA(isA<UnknownAccountException>()),
      );
    });

    test('removing the only account must go through logoutLast', () {
      expect(
        () => AccountTransitions.remove(
          Active(accounts: [a], activeId: 'a'),
          'a',
        ),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });

    test('removing during a switch is rejected (P6)', () {
      expect(
        () => AccountTransitions.remove(
          Switching(accounts: [a, b], from: 'a', to: 'b'),
          'b',
        ),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });

    test('removing the logged-out last account is rejected', () {
      expect(
        () => AccountTransitions.remove(LastLoggedOut(account: _out('a')), 'a'),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });
  });

  group('accounts that wait for their removal', () {
    Account waiting(String id) =>
        Account(id: id, status: AccountStatus.unavailable);

    test('a boot with only waiting accounts keeps them listed', () {
      expect(
        AccountTransitions.initialize(const Booting(), [waiting('w')]),
        NoAccount(accounts: [waiting('w')]),
      );
    });

    test(
      'a boot with waiting accounts and a placeholder offers the placeholder',
      () {
        expect(
          AccountTransitions.initialize(const Booting(), [
            waiting('w'),
            _out('p'),
          ]),
          NoAccount(candidateId: 'p', accounts: [waiting('w')]),
        );
      },
    );

    test('a login after that keeps them listed', () {
      expect(
        AccountTransitions.add(NoAccount(accounts: [waiting('w')]), a),
        Active(accounts: [waiting('w'), a], activeId: 'a'),
      );
    });

    test('holding a non-active account keeps the active one', () {
      expect(
        AccountTransitions.markUnavailable(
          Active(accounts: [a, b], activeId: 'a'),
          'b',
        ),
        Active(
          accounts: [a, b.withStatus(AccountStatus.unavailable)],
          activeId: 'a',
        ),
      );
    });

    test('holding the active account activates the next logged-in one', () {
      final state = AccountTransitions.markUnavailable(
        Active(accounts: [a, b], activeId: 'a'),
        'a',
      );

      expect((state as Active).activeId, 'b');
      expect(state.accounts.first.status, AccountStatus.unavailable);
    });

    test(
      'holding the active account with no logged-in survivor logs nobody in',
      () {
        final state = AccountTransitions.markUnavailable(
          Active(accounts: [a, waiting('w')], activeId: 'a'),
          'a',
        );

        expect(state, isA<NoAccount>());
        expect(state.accounts.map((x) => x.id), ['a', 'w']);
        expect(
          state.accounts.every((x) => x.status == AccountStatus.unavailable),
          isTrue,
        );
      },
    );

    test('holding an account that is already held changes nothing', () {
      final held = NoAccount(accounts: [waiting('w')]);

      expect(AccountTransitions.markUnavailable(held, 'w'), held);
    });

    test(
      'removing the active account with only waiting survivors logs nobody in',
      () {
        expect(
          AccountTransitions.remove(
            Active(accounts: [a, waiting('w')], activeId: 'a'),
            'a',
          ),
          NoAccount(accounts: [waiting('w')]),
        );
      },
    );

    test(
      'removing the active account keeps the placeholder as the next login',
      () {
        expect(
          AccountTransitions.remove(
            Active(accounts: [a, _out('p')], activeId: 'a'),
            'a',
          ),
          const NoAccount(candidateId: 'p'),
        );
      },
    );

    test('a waiting account is removed from NoAccount', () {
      expect(
        AccountTransitions.remove(
          NoAccount(candidateId: 'p', accounts: [waiting('w'), waiting('v')]),
          'w',
        ),
        NoAccount(candidateId: 'p', accounts: [waiting('v')]),
      );
    });

    test('an unknown account is not removed from NoAccount', () {
      expect(
        () => AccountTransitions.remove(const NoAccount(), 'x'),
        throwsA(isA<UnknownAccountException>()),
      );
    });
  });

  group('logoutLast', () {
    test('the only account becomes LastLoggedOut and is kept', () {
      expect(
        AccountTransitions.logoutLast(Active(accounts: [a], activeId: 'a')),
        const LastLoggedOut(
          account: Account(
            id: 'a',
            userId: '@a:server',
            status: AccountStatus.loggedOut,
          ),
        ),
      );
    });

    test('accounts that wait for their removal stay listed and the logged-out '
        'one is the candidate of the next login', () {
      final waiting = a.withStatus(AccountStatus.unavailable);
      expect(
        AccountTransitions.logoutLast(
          Active(accounts: [waiting, b], activeId: 'b'),
        ),
        NoAccount(candidateId: 'b', accounts: [waiting]),
      );
    });

    test('is rejected with several accounts or in another state', () {
      expect(
        () => AccountTransitions.logoutLast(
          Active(accounts: [a, b], activeId: 'a'),
        ),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
      expect(
        () => AccountTransitions.logoutLast(const NoAccount()),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });
  });

  test('transitions leave the input state unchanged', () {
    final input = Active(accounts: [a, b], activeId: 'a');
    AccountTransitions.beginSwitch(input, 'b');
    AccountTransitions.remove(input, 'a');
    AccountTransitions.add(input, c);
    expect(input, Active(accounts: [a, b], activeId: 'a'));
    expect(input.accounts, [a, b]);

    final switching = Switching(accounts: [a, b], from: 'a', to: 'b');
    AccountTransitions.completeSwitch(switching, 0);
    AccountTransitions.failSwitch(switching, 0);
    AccountTransitions.beginSwitch(switching, 'a');
    expect(switching, Switching(accounts: [a, b], from: 'a', to: 'b'));

    final loggedOut = LastLoggedOut(account: _out('a'));
    AccountTransitions.add(loggedOut, a);
    expect(loggedOut, LastLoggedOut(account: _out('a')));
  });

  test('an init error is dropped when the status changes', () {
    final failed = _failed('f', 1);
    expect(failed.withStatus(AccountStatus.loggedOut).initError, isNull);
    expect(failed.withStatus(AccountStatus.initFailed).initError, 1);
  });

  test('state collections are unmodifiable', () {
    final source = [a, b];
    final state = Active(accounts: source, activeId: 'a');
    source.add(c);
    expect(state.accounts, [a, b]);
    expect(() => state.accounts.add(c), throwsUnsupportedError);
  });
}
