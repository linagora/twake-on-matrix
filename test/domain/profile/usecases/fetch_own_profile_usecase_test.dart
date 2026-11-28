import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/exceptions/profile_exception.dart';
import 'package:twake_chat/domain/profile/usecases/fetch_own_profile_usecase.dart';

import '../fake_profile_repository.dart';

void main() {
  const alice = AccountProfile(userId: '@alice:server', displayName: 'Alice');

  test('execute_withKnownUser_returnsTheProfile', () async {
    // Arrange
    final repository = FakeProfileRepository(profile: alice);

    // Act
    final result = await FetchOwnProfileUseCase(
      repository,
    ).execute('@alice:server');

    // Assert
    expect(result, alice);
    expect(repository.profileCalls, [('@alice:server', false)]);
  });

  test('execute_withFresh_asksTheRepositoryForAFreshRead', () async {
    // Arrange
    final repository = FakeProfileRepository()..freshProfile = alice;

    // Act
    final result = await FetchOwnProfileUseCase(
      repository,
    ).execute('@alice:server', fresh: true);

    // Assert
    expect(result, alice);
    expect(repository.profileCalls, [('@alice:server', true)]);
  });

  test('execute_whenTheRepositoryThrows_throwsFetchOwnProfileException', () {
    // Arrange
    final error = Exception('network');
    final repository = FakeProfileRepository()..profileError = error;

    // Act
    final result = FetchOwnProfileUseCase(repository).execute('@alice:server');

    // Assert
    expect(
      result,
      throwsA(
        isA<FetchOwnProfileException>().having((e) => e.cause, 'cause', error),
      ),
    );
  });
}
