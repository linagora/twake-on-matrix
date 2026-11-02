import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/usecases/retryable_push_removals_usecase.dart';
import 'package:twake_chat/domain/account/usecases/prune_pending_push_removals_usecase.dart';

import 'fake_push_removal_repository.dart';

void main() {
  const account = Account(
    id: 'a',
    userId: '@a:s',
    status: AccountStatus.loggedIn,
  );

  group('RetryablePushRemovalsUseCase', () {
    test('returns the pending accounts that still exist', () async {
      final repository = FakePushRemovalRepository(
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
      final repository = FakePushRemovalRepository(
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
}
