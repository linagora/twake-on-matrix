import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/profile/repositories/profile_repository_impl.provider.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/exceptions/profile_exception.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_controller.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';

import '../../../domain/profile/fake_profile_repository.dart';

void main() {
  const alice = AccountProfile(userId: '@alice:server', displayName: 'Alice');
  const bob = AccountProfile(userId: '@bob:server', displayName: 'Bob');

  late FakeProfileRepository repository;

  ProviderContainer createContainer({String? userId = '@alice:server'}) {
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        activeUserIdProvider.overrideWith((ref) => userId),
        profileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    container.listen(settingsProfileControllerProvider, (_, _) {});
    return container;
  }

  Future<AccountProfile> loadProfile(ProviderContainer container) async =>
      (await container.read(settingsProfileControllerProvider.future)).profile;

  AccountProfile? shownProfile(ProviderContainer container) =>
      container.read(settingsProfileControllerProvider).value?.profile;

  setUp(() {
    repository = FakeProfileRepository(profile: alice, accounts: [alice, bob]);
  });

  test('build_withActiveUser_loadsTheOwnProfile', () async {
    // Arrange
    final container = createContainer();

    // Act
    final profile = await loadProfile(container);

    // Assert
    expect(profile, alice);
    expect(repository.profileCalls, [('@alice:server', false)]);
  });

  test('build_whenTheLookupFindsNothing_showsTheUserIdAlone', () async {
    // Arrange
    repository.profile = null;
    final container = createContainer();

    // Act
    final profile = await loadProfile(container);

    // Assert
    expect(profile, const AccountProfile(userId: '@alice:server'));
  });

  test('build_whenTheLookupFails_showsTheUserIdAlone', () async {
    // Arrange
    repository.profileError = Exception('network');
    final container = createContainer();

    // Act
    final profile = await loadProfile(container);

    // Assert
    expect(profile, const AccountProfile(userId: '@alice:server'));
  });

  test('build_withoutActiveUser_fails', () async {
    // Arrange
    final container = createContainer(userId: null);

    // Act
    final load = loadProfile(container);

    // Assert
    await expectLater(load, throwsA(isA<NoActiveClientException>()));
  });

  SettingsProfileController controllerOf(ProviderContainer container) =>
      container.read(settingsProfileControllerProvider.notifier);

  Future<void> flushRefresh() => Future<void>.delayed(Duration.zero);

  test('save_withNewName_showsTheSavedProfile', () async {
    // Arrange
    final container = createContainer();
    await loadProfile(container);

    // Act
    await controllerOf(container).save(displayName: 'Alicia');
    await flushRefresh();

    // Assert
    const renamed = AccountProfile(
      userId: '@alice:server',
      displayName: 'Alicia',
    );
    expect(repository.writes, ['Alicia']);
    expect(repository.announced, [renamed]);
    expect(shownProfile(container), renamed);
  });

  test('save_thenTheServerAnswers_showsTheServerProfile', () async {
    // Arrange
    final container = createContainer();
    await loadProfile(container);
    const fresh = AccountProfile(userId: '@alice:server', displayName: 'Ali');
    repository.freshProfile = fresh;

    // Act
    await controllerOf(container).save(displayName: 'Alicia');
    await flushRefresh();

    // Assert
    expect(repository.profileCalls.last, ('@alice:server', true));
    expect(shownProfile(container), fresh);
  });

  test('save_whileAnOlderRefreshIsPending_keepsTheNewerSave', () async {
    // Arrange
    final container = createContainer();
    await loadProfile(container);
    const first = AccountProfile(userId: '@alice:server', displayName: 'A1');
    const second = AccountProfile(userId: '@alice:server', displayName: 'A2');
    final staleRead = Completer<void>();
    repository
      ..freshProfile = first
      ..pendingFresh = staleRead;
    await controllerOf(container).save(displayName: 'A1');
    repository
      ..freshProfile = second
      ..pendingFresh = null;
    await controllerOf(container).save(displayName: 'A2');
    await flushRefresh();

    // Act
    staleRead.complete();
    await flushRefresh();

    // Assert
    expect(shownProfile(container), second);
  });

  test('save_whenTheServerRejects_throwsAndKeepsTheProfile', () async {
    // Arrange
    final container = createContainer();
    await loadProfile(container);
    repository.writeError = Exception('M_FORBIDDEN');

    // Act
    final save = controllerOf(container).save(displayName: 'Alicia');

    // Assert
    await expectLater(save, throwsA(isA<SaveOwnProfileException>()));
    expect(shownProfile(container), alice);
  });

  test('save_whenAWriteFails_showsWhatTheServerHas', () async {
    // Arrange
    final container = createContainer();
    await loadProfile(container);
    const partlySaved = AccountProfile(
      userId: '@alice:server',
      displayName: 'Alice',
      avatarUrl: null,
    );
    repository
      ..writeError = Exception('M_FORBIDDEN')
      ..freshProfile = partlySaved.copyWith(
        avatarUrl: Uri.parse('mxc://server/new'),
      );

    // Act
    await expectLater(
      controllerOf(container).save(displayName: 'Alicia'),
      throwsA(isA<SaveOwnProfileException>()),
    );
    await flushRefresh();

    // Assert
    expect(repository.profileCalls.last, ('@alice:server', true));
    expect(shownProfile(container)?.avatarUrl, Uri.parse('mxc://server/new'));
  });

  test('save_afterDispose_completesWithoutError', () async {
    // Arrange
    final container = createContainer();
    await loadProfile(container);
    final pending = Completer<void>();
    repository.pendingWrite = pending;
    final save = controllerOf(container).save(displayName: 'Alicia');

    // Act
    container.dispose();
    pending.complete();

    // Assert
    await expectLater(save, completes);
  });

  test('removeAvatar_withAvatar_showsTheProfileWithoutAvatar', () async {
    // Arrange
    repository.profile = alice.copyWith(
      avatarUrl: Uri.parse('mxc://server/old'),
    );
    final container = createContainer();
    await loadProfile(container);

    // Act
    await controllerOf(container).removeAvatar();
    await flushRefresh();

    // Assert
    expect(repository.writes, [null]);
    expect(shownProfile(container), alice);
  });

  test('removeAvatar_whenTheServerFails_throwsAndKeepsTheAvatar', () async {
    // Arrange
    final withAvatar = alice.copyWith(avatarUrl: Uri.parse('mxc://server/old'));
    repository.profile = withAvatar;
    final container = createContainer();
    await loadProfile(container);
    repository.writeError = Exception('network');

    // Act
    final remove = controllerOf(container).removeAvatar();

    // Assert
    await expectLater(remove, throwsA(isA<RemoveOwnAvatarException>()));
    expect(shownProfile(container), withAvatar);
  });

  test('settingsProfileAccounts_withAccounts_returnsThem', () async {
    // Arrange
    final container = createContainer();

    // Act
    final accounts = await container.read(
      settingsProfileAccountsProvider.future,
    );

    // Assert
    expect(accounts, [alice, bob]);
  });

  test('settingsProfileAccounts_whenTheReadFails_returnsNull', () async {
    // Arrange
    repository.accountsError = Exception('database');
    final container = createContainer();

    // Act
    final accounts = await container.read(
      settingsProfileAccountsProvider.future,
    );

    // Assert
    expect(accounts, isNull);
  });
}
