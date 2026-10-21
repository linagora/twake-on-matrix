import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/repositories/account_boot_port.dart';
import 'package:twake_chat/domain/account/repositories/account_repository.dart';
import 'package:twake_chat/domain/account/usecases/adopt_boot_accounts_interactor.dart';

class _FakeRepository extends Fake implements AccountRepository {
  _FakeRepository(this.known);

  final List<Account> known;

  @override
  List<Account> registeredAccounts() => known;
}

class _FakeBootPort implements AccountBootPort {
  _FakeBootPort(this.booted);

  final List<Account> booted;
  final List<Set<String>> calls = [];

  @override
  List<Account> adopt({Set<String> pendingRemovals = const {}}) {
    calls.add(pendingRemovals);
    return booted;
  }
}

void main() {
  const account = Account(
    id: 'a',
    userId: '@a:s',
    status: AccountStatus.loggedIn,
  );
  const other = Account(id: 'b', status: AccountStatus.loggedOut);

  AdoptBootAccountsInteractor build(
    List<Account> known,
    _FakeBootPort bootPort,
  ) => AdoptBootAccountsInteractor(
    repository: _FakeRepository(known),
    bootPort: bootPort,
  );

  test('adopts the boot accounts when the repository knows none', () {
    final bootPort = _FakeBootPort(const [account]);

    final adopted = build(const [], bootPort).execute(pendingRemovals: {'p'});

    expect(adopted, const [account]);
    expect(bootPort.calls, [
      {'p'},
    ]);
  });

  test('keeps the accounts the repository already knows', () {
    final bootPort = _FakeBootPort(const [account]);

    final adopted = build(const [other], bootPort).execute();

    expect(adopted, const [other]);
    expect(bootPort.calls, isEmpty);
  });
}
