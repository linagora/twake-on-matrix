import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'account_test_support.dart';

const _transitions = accountTransitions;

Account _in(String id) => accountWith(id, AccountStatus.loggedIn);

Account _out(String id) => accountWith(id, AccountStatus.loggedOut);

Account _waiting(String id) => accountWith(id, AccountStatus.unavailable);

Switching _firstSwitch(Account a, Account b, Account c) =>
    _transitions.beginSwitch(
          Active(accounts: [a, b, c], activeId: a.id),
          b.id,
          seq: 1,
        )
        as Switching;

void main() {
  final a = _in('a');
  final b = _in('b');
  final c = _in('c');

  group('initialize', () {
    test('logged-out boot with a placeholder gives NoAccount(candidate)', () {
      expect(
        _transitions.initialize(const Booting(), [_out('p')]),
        const NoAccount(candidateId: 'p'),
      );
    });

    test('logged-out boot with an empty list gives NoAccount(null)', () {
      expect(_transitions.initialize(const Booting(), []), const NoAccount());
    });

    test('persisted account present becomes active', () {
      expect(
        _transitions.initialize(const Booting(), [
          a,
          b,
        ], persistedUserId: '@b:server'),
        Active(accounts: [a, b], activeId: 'b'),
      );
    });

    test('persisted account missing falls back to the first logged-in', () {
      expect(
        _transitions.initialize(const Booting(), [a, b]),
        Active(accounts: [a, b], activeId: 'a'),
      );
    });

    test('persisted account unknown falls back to the first logged-in', () {
      expect(
        _transitions.initialize(const Booting(), [
          a,
          b,
        ], persistedUserId: '@zzz:server'),
        Active(accounts: [a, b], activeId: 'a'),
      );
    });

    test('a logged-out account is skipped as initial active', () {
      expect(
        _transitions.initialize(const Booting(), [_out('x'), b]),
        Active(accounts: [_out('x'), b], activeId: 'b'),
      );
    });

    test(
      'the first logged-out account is the placeholder of the next login',
      () {
        expect(
          _transitions.initialize(const Booting(), [
            _waiting('w'),
            _out('p'),
            _out('q'),
          ]),
          NoAccount(candidateId: 'p', accounts: [_waiting('w')]),
        );
      },
    );

    test('is rejected outside Booting', () {
      expect(
        () => _transitions.initialize(const NoAccount(), [a]),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });
  });

  group('add', () {
    test('first login from NoAccount gives Active([a], a)', () {
      expect(
        _transitions.add(const NoAccount(candidateId: 'p'), a),
        Active(accounts: [a], activeId: 'a'),
      );
    });

    test('add on Active appends and keeps the active account', () {
      expect(
        _transitions.add(Active(accounts: [a], activeId: 'a'), b),
        Active(accounts: [a, b], activeId: 'a'),
      );
    });

    test('add then switch makes the new account active', () {
      var state = _transitions.add(Active(accounts: [a], activeId: 'a'), b);
      state = _transitions.beginSwitch(state, 'b', seq: 1);
      expect(state, Switching(accounts: [a, b], from: 'a', to: 'b', seq: 1));
      state = _transitions.completeSwitch(state, 1);
      expect(state, Active(accounts: [a, b], activeId: 'b'));
    });

    test('login again after the last logout gives Active([a], a)', () {
      expect(
        _transitions.add(LastLoggedOut(account: _out('a')), a),
        Active(accounts: [a], activeId: 'a'),
      );
    });

    test('a different account after the last logout is rejected', () {
      expect(
        () => _transitions.add(LastLoggedOut(account: _out('a')), b),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });

    test('a duplicate id is rejected', () {
      expect(
        () => _transitions.add(Active(accounts: [a], activeId: 'a'), a),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });

    test('a duplicate id is rejected from NoAccount too', () {
      expect(
        () => _transitions.add(NoAccount(accounts: [_waiting('a')]), a),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });

    test('an account that is not logged in is rejected', () {
      expect(
        () => _transitions.add(const NoAccount(), _out('x')),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });

    test('is rejected while Booting or Switching', () {
      expect(
        () => _transitions.add(const Booting(), a),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
      expect(
        () => _transitions.add(
          Switching(accounts: [a, b], from: 'a', to: 'b', seq: 1),
          c,
        ),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });
  });

  group('beginSwitch / completeSwitch / failSwitch', () {
    final active = Active(accounts: [a, b], activeId: 'a');

    test('switch goes through Switching then Active', () {
      final switching = _transitions.beginSwitch(active, 'b', seq: 1);
      expect(
        switching,
        Switching(accounts: [a, b], from: 'a', to: 'b', seq: 1),
      );
      expect(
        _transitions.completeSwitch(switching, 1),
        Active(accounts: [a, b], activeId: 'b'),
      );
    });

    test('switch to the active account is a no-op', () {
      expect(_transitions.beginSwitch(active, 'a', seq: 1), same(active));
    });

    test('switch to an unknown account throws', () {
      expect(
        () => _transitions.beginSwitch(active, 'x', seq: 1),
        throwsA(isA<UnknownAccountException>()),
      );
      expect(
        () => _transitions.beginSwitch(const NoAccount(), 'x', seq: 1),
        throwsA(isA<UnknownAccountException>()),
      );
    });

    test('a second switch supersedes the first and keeps the origin', () {
      final first = _transitions.beginSwitch(
        Active(accounts: [a, b, c], activeId: 'a'),
        'b',
        seq: 1,
      );
      expect(
        _transitions.beginSwitch(first, 'c', seq: 2),
        Switching(accounts: [a, b, c], from: 'a', to: 'c', seq: 2),
      );
    });

    test('switching back to the origin during a switch returns to Active', () {
      final first = _transitions.beginSwitch(active, 'b', seq: 1);
      expect(_transitions.beginSwitch(first, 'a', seq: 2), active);
    });

    test('a stale handler cannot settle a newer switch', () {
      final first = _firstSwitch(a, b, c);
      final second = _transitions.beginSwitch(first, 'c', seq: 2);
      for (final settle in [
        _transitions.completeSwitch,
        _transitions.failSwitch,
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
        _transitions.completeSwitch(second, 2),
        Active(accounts: [a, b, c], activeId: 'c'),
      );
    });

    test('a newer switch to the same target is also told apart', () {
      final first = _firstSwitch(a, b, c);
      final again = Switching(
        accounts: first.accounts,
        from: 'a',
        to: 'b',
        seq: 2,
      );
      expect(
        () => _transitions.completeSwitch(again, 1),
        throwsA(isA<SwitchSupersededException>()),
      );
    });

    test('a failed switch returns to Active(from)', () {
      final switching = _transitions.beginSwitch(active, 'b', seq: 1);
      expect(_transitions.failSwitch(switching, 1), active);
    });

    test('complete and fail outside Switching are rejected', () {
      expect(
        () => _transitions.completeSwitch(active, 0),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
      expect(
        () => _transitions.failSwitch(active, 0),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });

    test('a logged-out or waiting target is rejected', () {
      final state = Active(
        accounts: [a, _out('x'), _waiting('w')],
        activeId: 'a',
      );
      for (final id in ['x', 'w']) {
        expect(
          () => _transitions.beginSwitch(state, id, seq: 1),
          throwsA(isA<InvalidAccountTransitionException>()),
        );
      }
    });
  });

  group('remove', () {
    test('removing a non-active account keeps the active one', () {
      expect(
        _transitions.remove(Active(accounts: [a, b, c], activeId: 'c'), 'a'),
        Active(accounts: [b, c], activeId: 'c'),
      );
    });

    test('removing the active account picks the follower', () {
      expect(
        _transitions.remove(Active(accounts: [a, b, c], activeId: 'a'), 'a'),
        Active(accounts: [b, c], activeId: 'b'),
      );
    });

    test('removing the active last account picks the previous one', () {
      expect(
        _transitions.remove(Active(accounts: [a, b], activeId: 'b'), 'b'),
        Active(accounts: [a], activeId: 'a'),
      );
    });

    test('removing an unknown account throws', () {
      expect(
        () => _transitions.remove(Active(accounts: [a, b], activeId: 'a'), 'x'),
        throwsA(isA<UnknownAccountException>()),
      );
      expect(
        () => _transitions.remove(const Booting(), 'x'),
        throwsA(isA<UnknownAccountException>()),
      );
    });

    test('removing the only account must go through logoutLast', () {
      expect(
        () => _transitions.remove(Active(accounts: [a], activeId: 'a'), 'a'),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });

    test('removing during a switch is rejected', () {
      expect(
        () => _transitions.remove(
          Switching(accounts: [a, b], from: 'a', to: 'b', seq: 1),
          'b',
        ),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });

    test('removing the logged-out last account is rejected', () {
      expect(
        () => _transitions.remove(LastLoggedOut(account: _out('a')), 'a'),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });
  });

  group('accounts that wait for their removal', () {
    test('a boot with only waiting accounts keeps them listed', () {
      expect(
        _transitions.initialize(const Booting(), [_waiting('w')]),
        NoAccount(accounts: [_waiting('w')]),
      );
    });

    test(
      'a boot with waiting accounts and a placeholder offers the placeholder',
      () {
        expect(
          _transitions.initialize(const Booting(), [_waiting('w'), _out('p')]),
          NoAccount(candidateId: 'p', accounts: [_waiting('w')]),
        );
      },
    );

    test('a login after that keeps them listed', () {
      expect(
        _transitions.add(NoAccount(accounts: [_waiting('w')]), a),
        Active(accounts: [_waiting('w'), a], activeId: 'a'),
      );
    });

    test('holding a non-active account keeps the active one', () {
      expect(
        _transitions.markUnavailable(
          Active(accounts: [a, b], activeId: 'a'),
          'b',
        ),
        Active(
          accounts: [
            a,
            b.copyWith(status: AccountStatus.unavailable),
          ],
          activeId: 'a',
        ),
      );
    });

    test('holding the active account activates the next logged-in one', () {
      final state = _transitions.markUnavailable(
        Active(accounts: [a, b], activeId: 'a'),
        'a',
      );

      expect((state as Active).activeId, 'b');
      expect(state.accounts.first.status, AccountStatus.unavailable);
    });

    test(
      'holding the active account with no logged-in survivor logs nobody in',
      () {
        final state = _transitions.markUnavailable(
          Active(accounts: [a, _waiting('w')], activeId: 'a'),
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
      final held = NoAccount(accounts: [_waiting('w')]);

      expect(_transitions.markUnavailable(held, 'w'), held);
    });

    test('holding is rejected outside Active and NoAccount', () {
      final switching = Switching(accounts: [a, b], from: 'a', to: 'b', seq: 1);
      expect(
        () => _transitions.markUnavailable(switching, 'a'),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
      expect(
        () => _transitions.markUnavailable(
          LastLoggedOut(account: _out('a')),
          'a',
        ),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
      expect(
        () => _transitions.markUnavailable(const Booting(), 'a'),
        throwsA(isA<UnknownAccountException>()),
      );
    });

    test(
      'removing the active account with only waiting survivors logs nobody in',
      () {
        expect(
          _transitions.remove(
            Active(accounts: [a, _waiting('w')], activeId: 'a'),
            'a',
          ),
          NoAccount(accounts: [_waiting('w')]),
        );
      },
    );

    test(
      'removing the active account keeps the placeholder as the next login',
      () {
        expect(
          _transitions.remove(
            Active(accounts: [a, _out('p')], activeId: 'a'),
            'a',
          ),
          const NoAccount(candidateId: 'p'),
        );
      },
    );

    test('a waiting account is removed from NoAccount', () {
      expect(
        _transitions.remove(
          NoAccount(candidateId: 'p', accounts: [_waiting('w'), _waiting('v')]),
          'w',
        ),
        NoAccount(candidateId: 'p', accounts: [_waiting('v')]),
      );
    });

    test('an unknown account is not removed from NoAccount', () {
      expect(
        () => _transitions.remove(const NoAccount(), 'x'),
        throwsA(isA<UnknownAccountException>()),
      );
    });
  });

  group('logoutLast', () {
    test('the only account becomes LastLoggedOut and is kept', () {
      expect(
        _transitions.logoutLast(Active(accounts: [a], activeId: 'a')),
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
      final waiting = a.copyWith(status: AccountStatus.unavailable);
      expect(
        _transitions.logoutLast(Active(accounts: [waiting, b], activeId: 'b')),
        NoAccount(candidateId: 'b', accounts: [waiting]),
      );
    });

    test(
      'a logged-out account beside it is dropped, not a reason to reject',
      () {
        final waiting = a.copyWith(status: AccountStatus.unavailable);
        expect(
          _transitions.logoutLast(
            Active(accounts: [waiting, _out('p'), b], activeId: 'b'),
          ),
          NoAccount(candidateId: 'b', accounts: [waiting]),
        );
      },
    );

    test('is rejected with several accounts or in another state', () {
      expect(
        () => _transitions.logoutLast(Active(accounts: [a, b], activeId: 'a')),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
      expect(
        () => _transitions.logoutLast(const NoAccount()),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
    });
  });

  test('transitions leave the input state unchanged', () {
    final input = Active(accounts: [a, b], activeId: 'a');
    _transitions.beginSwitch(input, 'b', seq: 1);
    _transitions.remove(input, 'a');
    _transitions.add(input, c);
    expect(input, Active(accounts: [a, b], activeId: 'a'));
    expect(input.accounts, [a, b]);

    final switching = Switching(accounts: [a, b], from: 'a', to: 'b', seq: 1);
    _transitions.completeSwitch(switching, 1);
    _transitions.failSwitch(switching, 1);
    _transitions.beginSwitch(switching, 'a', seq: 2);
    expect(switching, Switching(accounts: [a, b], from: 'a', to: 'b', seq: 1));

    final loggedOut = LastLoggedOut(account: _out('a'));
    _transitions.add(loggedOut, a);
    expect(loggedOut, LastLoggedOut(account: _out('a')));
  });

  test('an invalid transition names the state it came from', () {
    final active = Active(accounts: [a], activeId: 'a');
    final switching = Switching(accounts: [a, b], from: 'a', to: 'b', seq: 1);
    final calls = <String, void Function()>{
      'Booting': () => _transitions.add(const Booting(), a),
      'NoAccount': () => _transitions.completeSwitch(const NoAccount(), 1),
      'Active': () => _transitions.completeSwitch(active, 1),
      'Switching': () => _transitions.add(switching, c),
      'LastLoggedOut': () =>
          _transitions.completeSwitch(LastLoggedOut(account: _out('a')), 1),
    };
    calls.forEach((name, call) {
      expect(
        call,
        throwsA(
          isA<InvalidAccountTransitionException>().having(
            (e) => e.stateName,
            'stateName',
            name,
          ),
        ),
      );
    });
  });

  test('state collections are unmodifiable', () {
    final state = Active(accounts: [a, b], activeId: 'a');
    expect(() => state.accounts.add(c), throwsUnsupportedError);
  });

  test('initialize keeps its own copy of the accounts', () {
    final source = [a, b];
    final state = _transitions.initialize(const Booting(), source);
    source.add(c);
    expect(state.accounts, [a, b]);
  });
}
