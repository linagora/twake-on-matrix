import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';
import 'package:twake_chat/data/profile/datasources/account_profiles_datasource.dart';
import 'package:twake_chat/data/profile/datasources/own_profile_datasource.dart';
import 'package:twake_chat/data/profile/repositories/profile_repository_impl.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/entities/avatar_upload.dart';

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

class _FakeOwnProfileDatasource implements OwnProfileDatasource {
  final List<Object?> calls = [];

  @override
  Future<Uri> uploadAvatar(AvatarUpload avatar) async {
    calls.add(avatar);
    return Uri.parse('mxc://server/new');
  }

  @override
  Future<void> setAvatar(Uri? avatarUrl) async => calls.add(avatarUrl);

  @override
  Future<void> setDisplayName(String displayName) async =>
      calls.add(displayName);

  @override
  void announce(AccountProfile profile) => calls.add(profile);
}

void main() {
  ProfileRepositoryImpl createRepository(
    MatrixUserProfile? profile, {
    List<AccountProfile> accounts = const [],
  }) => ProfileRepositoryImpl(
    _FakeMatrixProfileDatasource(profile),
    _FakeAccountProfilesDatasource(accounts),
    _FakeOwnProfileDatasource(),
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
      _FakeOwnProfileDatasource(),
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

  ProfileRepositoryImpl repositoryWith(_FakeOwnProfileDatasource own) =>
      ProfileRepositoryImpl(
        _FakeMatrixProfileDatasource(null),
        _FakeAccountProfilesDatasource(const []),
        own,
      );

  test('uploadAvatar_withBytes_returnsTheDatasourceUri', () async {
    // Arrange
    final own = _FakeOwnProfileDatasource();
    final avatar = AvatarUpload.fromBytes(bytes: Uint8List(1), name: 'a.png');

    // Act
    final uri = await repositoryWith(own).uploadAvatar(avatar);

    // Assert
    expect(uri, Uri.parse('mxc://server/new'));
    expect(own.calls, [avatar]);
  });

  test('saveOwnAvatar_withNull_forwardsNull', () async {
    // Arrange
    final own = _FakeOwnProfileDatasource();

    // Act
    await repositoryWith(own).saveOwnAvatar(null);

    // Assert
    expect(own.calls, [null]);
  });

  test('saveOwnDisplayName_withName_forwardsIt', () async {
    // Arrange
    final own = _FakeOwnProfileDatasource();

    // Act
    await repositoryWith(own).saveOwnDisplayName('Alice');

    // Assert
    expect(own.calls, ['Alice']);
  });

  test('announceOwnProfile_withProfile_forwardsIt', () {
    // Arrange
    final own = _FakeOwnProfileDatasource();
    const alice = AccountProfile(userId: '@alice:server');

    // Act
    repositoryWith(own).announceOwnProfile(alice);

    // Assert
    expect(own.calls, [alice]);
  });
}
