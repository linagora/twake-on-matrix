import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/exceptions/profile_exception.dart';
import 'package:twake_chat/domain/profile/usecases/fetch_account_profiles_usecase.dart';

import '../fake_profile_repository.dart';

void main() {
  test('execute_withAccounts_returnsTheirProfiles', () async {
    // Arrange
    const accounts = [
      AccountProfile(userId: '@alice:server'),
      AccountProfile(userId: '@bob:server'),
    ];
    final repository = FakeProfileRepository(accounts: accounts);

    // Act
    final result = await FetchAccountProfilesUseCase(repository).execute();

    // Assert
    expect(result, accounts);
  });

  test(
    'execute_whenTheRepositoryThrows_throwsFetchAccountProfilesException',
    () {
      // Arrange
      final error = Exception('database');
      final repository = FakeProfileRepository()..accountsError = error;

      // Act
      final result = FetchAccountProfilesUseCase(repository).execute();

      // Assert
      expect(
        result,
        throwsA(
          isA<FetchAccountProfilesException>().having(
            (e) => e.cause,
            'cause',
            error,
          ),
        ),
      );
    },
  );
}
