import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';
import 'package:twake_chat/data/profile/datasources/account_profiles_datasource.dart';
import 'package:twake_chat/data/profile/repositories/profile_repository_impl.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';

class _FakeMatrixProfileDatasource implements MatrixProfileDatasource {
  _FakeMatrixProfileDatasource(this.profile);

  final MatrixUserProfile? profile;
  final List<(String, bool)> calls = [];

  @override
  Future<MatrixUserProfile?> fetchProfile(
    String matrixId, {
    bool fresh = false,
  }) async {
    calls.add((matrixId, fresh));
    return profile;
  }
}

class _FakeAccountProfilesDatasource implements AccountProfilesDatasource {
  _FakeAccountProfilesDatasource(this.accounts);

  final List<AccountProfile> accounts;

  @override
  Future<List<AccountProfile>> fetchAccountProfiles() async => accounts;
}

void main() {
  ProfileRepositoryImpl createRepository(
    MatrixUserProfile? profile, {
    List<AccountProfile> accounts = const [],
  }) => ProfileRepositoryImpl(
    _FakeMatrixProfileDatasource(profile),
    _FakeAccountProfilesDatasource(accounts),
  );

  test('fetchProfile_withMxcAvatar_returnsTheParsedUri', () async {
    // Arrange
    final repository = createRepository(
      const MatrixUserProfile(
        matrixId: '@alice:server',
        displayName: 'Alice',
        avatarUrl: 'mxc://server/avatar',
      ),
    );

    // Act
    final result = await repository.fetchProfile('@alice:server');

    // Assert
    expect(
      result,
      AccountProfile(
        userId: '@alice:server',
        displayName: 'Alice',
        avatarUrl: Uri.parse('mxc://server/avatar'),
      ),
    );
  });

  test('fetchProfile_whenTheLookupFindsNothing_returnsNull', () async {
    // Arrange
    final repository = createRepository(null);

    // Act
    final result = await repository.fetchProfile('@alice:server');

    // Assert
    expect(result, isNull);
  });

  test('fetchProfile_withFresh_asksTheDatasourceForAFreshRead', () async {
    // Arrange
    final datasource = _FakeMatrixProfileDatasource(null);
    final repository = ProfileRepositoryImpl(
      datasource,
      _FakeAccountProfilesDatasource(const []),
    );

    // Act
    await repository.fetchProfile('@alice:server', fresh: true);

    // Assert
    expect(datasource.calls, [('@alice:server', true)]);
  });

  test('fetchAccountProfiles_withAccounts_returnsTheDatasourceOnes', () async {
    // Arrange
    const accounts = [AccountProfile(userId: '@alice:server')];
    final repository = createRepository(null, accounts: accounts);

    // Act
    final result = await repository.fetchAccountProfiles();

    // Assert
    expect(result, accounts);
  });
}
