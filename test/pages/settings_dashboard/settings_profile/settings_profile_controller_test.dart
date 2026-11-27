import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/profile/repositories/profile_repository_impl.provider.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';
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

  test('applySaved_afterLoad_showsTheSavedProfile', () async {
    // Arrange
    final container = createContainer();
    await loadProfile(container);
    const renamed = AccountProfile(
      userId: '@alice:server',
      displayName: 'Alicia',
    );

    // Act
    container
        .read(settingsProfileControllerProvider.notifier)
        .applySaved(renamed);

    // Assert
    expect(shownProfile(container), renamed);
  });

  test('refresh_whenTheServerAnswers_showsTheServerProfile', () async {
    // Arrange
    final container = createContainer();
    await loadProfile(container);
    const fresh = AccountProfile(userId: '@alice:server', displayName: 'Ali');
    repository.freshProfile = fresh;

    // Act
    await container.read(settingsProfileControllerProvider.notifier).refresh();

    // Assert
    expect(repository.profileCalls.last, ('@alice:server', true));
    expect(shownProfile(container), fresh);
  });

  test('refresh_whenTheServerDoesNotAnswer_keepsTheProfile', () async {
    // Arrange
    final container = createContainer();
    await loadProfile(container);
    repository.freshProfile = null;

    // Act
    await container.read(settingsProfileControllerProvider.notifier).refresh();

    // Assert
    expect(shownProfile(container), alice);
  });

  test('refresh_afterDispose_completesWithoutError', () async {
    // Arrange
    final container = createContainer();
    await loadProfile(container);
    final pending = Completer<void>();
    repository
      ..freshProfile = bob
      ..pendingFresh = pending;
    final refresh = container
        .read(settingsProfileControllerProvider.notifier)
        .refresh();

    // Act
    container.dispose();
    pending.complete();

    // Assert
    await expectLater(refresh, completes);
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
