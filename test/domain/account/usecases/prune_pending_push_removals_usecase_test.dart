import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/usecases/prune_pending_push_removals_usecase.dart';

import 'fake_push_removal_repository.dart';

void main() {
  const account = Account(
    id: 'a',
    userId: '@a:s',
    status: AccountStatus.loggedIn,
  );

  group('PrunePendingPushRemovalsUseCase', () {
    test('drops the record of an account that is gone only', () async {
      final repository = FakePushRemovalRepository(
        registered: const [account],
        pending: {'a', 'gone'},
      );

      await PrunePendingPushRemovalsUseCase(repository: repository).execute();

      expect(repository.cleared, ['gone']);
    });

    test('one failing drop does not stop the others', () async {
      final repository = FakePushRemovalRepository(
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
