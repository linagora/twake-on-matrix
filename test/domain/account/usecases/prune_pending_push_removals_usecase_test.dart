import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/repositories/account_repository.dart';
import 'package:twake_chat/domain/account/usecases/prune_pending_push_removals_usecase.dart';

class _FakeRepository extends Fake implements AccountRepository {
  _FakeRepository({required this.registered, required this.pending});

  final List<Account> registered;
  final Set<String> pending;
  final List<String> cleared = [];
  final Set<String> failing = {};

  @override
  List<Account> registeredAccounts() => registered;

  @override
  Future<Set<String>> pendingPushRemovals() async => pending;

  @override
  Future<void> clearPushRemovalPending(String id) async {
    if (failing.contains(id)) throw StateError(id);
    cleared.add(id);
  }
}

void main() {
  const account = Account(
    id: 'a',
    userId: '@a:s',
    status: AccountStatus.loggedIn,
  );

  group('RetryablePushRemovalsUseCase', () {
    test('returns the pending accounts that still exist', () async {
      final repository = _FakeRepository(
        registered: const [account],
        pending: {'a', 'gone'},
      );

      final retryable = await RetryablePushRemovalsUseCase(
        repository: repository,
      ).execute();

      expect(retryable, ['a']);
      expect(repository.cleared, isEmpty);
    });

    test('does not depend on the drops', () async {
      final repository = _FakeRepository(
        registered: const [account],
        pending: {'gone', 'a'},
      )..failing.add('gone');

      await expectLater(
        PrunePendingPushRemovalsUseCase(repository: repository).execute(),
        throwsStateError,
      );
      final retryable = await RetryablePushRemovalsUseCase(
        repository: repository,
      ).execute();

      expect(retryable, ['a']);
    });
  });

  group('PrunePendingPushRemovalsUseCase', () {
    test('drops the record of an account that is gone only', () async {
      final repository = _FakeRepository(
        registered: const [account],
        pending: {'a', 'gone'},
      );

      await PrunePendingPushRemovalsUseCase(repository: repository).execute();

      expect(repository.cleared, ['gone']);
    });

    test('one failing drop does not stop the others', () async {
      final repository = _FakeRepository(
        registered: const [account],
        pending: {'gone-1', 'gone-2', 'a'},
      )..failing.add('gone-1');

      await expectLater(
        PrunePendingPushRemovalsUseCase(repository: repository).execute(),
        throwsStateError,
      );

      expect(repository.cleared, ['gone-2']);
    });
  });
}
