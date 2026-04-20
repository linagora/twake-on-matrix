// test/features/invitation/invitation_controller_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '03_invitation_exception.dart';
import '13_invitation_state.dart';
import '14_invitation_controller.dart';
import '15_invitation_providers.dart';
import '17_invitation_fakes.dart';

void main() {
  late FakeInvitationApiDataSource fakeApi;
  late FakeInvitationLocalDataSource fakeLocal;

  setUp(() {
    fakeApi = FakeInvitationApiDataSource();
    fakeLocal = FakeInvitationLocalDataSource();
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          invitationApiDataSourceProvider.overrideWithValue(fakeApi),
          invitationLocalDataSourceProvider.overrideWithValue(fakeLocal),
        ],
      );

  test('initial state is InvitationInitial when no cached link', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    final state = await container
        .read(invitationControllerProvider('!room:server').future);

    expect(state, isA<InvitationInitial>());
  });

  test('generateLink returns InvitationLinkReady with the link', () async {
    fakeApi.linkToReturn = 'https://invite.example.com/abc';
    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(invitationControllerProvider('!room:server').future);
    await container
        .read(invitationControllerProvider('!room:server').notifier)
        .generateLink();

    final state = container
        .read(invitationControllerProvider('!room:server'))
        .value;

    expect(state, isA<InvitationLinkReady>());
    expect(
      (state as InvitationLinkReady).link.url,
      'https://invite.example.com/abc',
    );
  });

  test('generateLink exposes InvitationDisabledException if disabled', () async {
    fakeApi.errorToThrow = const InvitationDisabledException();
    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(invitationControllerProvider('!room:server').future);
    await container
        .read(invitationControllerProvider('!room:server').notifier)
        .generateLink();

    final asyncState =
        container.read(invitationControllerProvider('!room:server'));

    expect(asyncState.hasError, isTrue);
    expect(asyncState.error, isA<InvitationDisabledException>());
  });

  test('sendInvitation transitions to InvitationSent', () async {
    fakeApi.linkToReturn = 'https://invite.example.com/abc';
    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(invitationControllerProvider('!room:server').future);
    await container
        .read(invitationControllerProvider('!room:server').notifier)
        .generateLink();
    await container
        .read(invitationControllerProvider('!room:server').notifier)
        .sendInvitation('@alice:server');

    final state = container
        .read(invitationControllerProvider('!room:server'))
        .value;

    expect(state, isA<InvitationSent>());
    expect((state as InvitationSent).targetUserId, '@alice:server');
  });
}
