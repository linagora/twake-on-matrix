import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/repositories/account_repository.dart';
import 'package:twake_chat/domain/account/usecases/prune_pending_push_removals.dart';

class _FakeRepository extends Fake implements AccountRepository {
  _FakeRepository({required this.registered, required this.pending});

  final List<Account> registered;
  final Set<String> pending;
  final List<String> cleared = [];

  @override
  List<Account> registeredAccounts() => registered;

  @override
  Future<Set<String>> pendingPushRemovals() async => pending;

  @override
  Future<void> clearPushRemovalPending(String id) async => cleared.add(id);
}

void main() {
  const account = Account(
    id: 'a',
    userId: '@a:s',
    status: AccountStatus.loggedIn,
  );

  test('returns the pending accounts that still exist', () async {
    final repository = _FakeRepository(
      registered: const [account],
      pending: {'a'},
    );

    final retryable = await PrunePendingPushRemovalsUseCase(
      repository: repository,
    ).execute();

    expect(retryable, ['a']);
    expect(repository.cleared, isEmpty);
  });

  test('drops the record of an account that is gone', () async {
    final repository = _FakeRepository(
      registered: const [account],
      pending: {'a', 'gone'},
    );

    final retryable = await PrunePendingPushRemovalsUseCase(
      repository: repository,
    ).execute();

    expect(retryable, ['a']);
    expect(repository.cleared, ['gone']);
  });
}
