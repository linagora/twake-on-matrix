import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/repository/new_group/new_group_repository.provider.dart';
import 'package:twake_chat/domain/exception/feed/feed_exception.dart';
import 'package:twake_chat/domain/exception/room/invite_user_exception.dart';
import 'package:twake_chat/domain/exception/spaces/space_exception.dart';
import 'package:twake_chat/domain/spaces/new_space.dart';
import 'package:twake_chat/domain/spaces/usecases/create_space_usecase.dart';
import 'package:twake_chat/domain/spaces/usecases/create_space_usecase.provider.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';
import 'package:twake_chat/pages/new_group/states/group_privacy_state.dart';
import 'package:twake_chat/pages/new_group/states/new_group_form.dart';
import 'package:twake_chat/pages/new_group/states/new_group_kind.dart';
import 'package:twake_chat/domain/repository/new_group/new_group_repository.dart';
import 'package:twake_chat/domain/usecase/feed/create_new_feed_interactor.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_controller.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_state.dart';
import 'package:twake_chat/pages/new_group/providers/new_feed_providers.dart';

import 'new_group_chat_info_controller_test.mocks.dart';
import '../../providers/fake_active_account.dart';

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<NewGroupRepository>(),
  MockSpec<CreateNewFeedInteractor>(),
  MockSpec<CreateSpaceUseCase>(),
])
void main() {
  provideDummy<NewSpace>(const NewSpace(name: ''));

  const roomId = '!room:example.com';

  late MockClient mockClient;
  late MockNewGroupRepository mockRepository;
  late MockCreateNewFeedInteractor mockFeedInteractor;
  late MockCreateSpaceUseCase mockCreateSpaceUseCase;
  late ProviderContainer container;
  late ProviderSubscription<NewGroupChatInfoState> subscription;

  setUp(() {
    mockClient = MockClient();
    mockRepository = MockNewGroupRepository();
    mockFeedInteractor = MockCreateNewFeedInteractor();
    mockCreateSpaceUseCase = MockCreateSpaceUseCase();
    when(mockRepository.createGroup(any)).thenAnswer((_) async => roomId);
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        ...activeAccountOverrides(mockClient),
        newGroupRepositoryProvider.overrideWithValue(mockRepository),
        createSpaceUseCaseProvider.overrideWithValue(mockCreateSpaceUseCase),
        createNewFeedInteractorProvider(
          mockClient,
        ).overrideWithValue(mockFeedInteractor),
      ],
    );
    subscription = container.listen(
      newGroupChatInfoControllerProvider,
      (_, _) {},
    );
  });

  tearDown(() => subscription.close());

  Future<void> create({
    String groupName = 'Team',
    List<String?> invitees = const ['@bob:example.com', '@carol:example.com'],
    NewGroupKind kind = NewGroupKind.group,
    String? parentSpaceId,
    GroupPrivacyState privacy = const GroupPrivacyState(),
  }) => container
      .read(newGroupChatInfoControllerProvider.notifier)
      .create(
        NewGroupForm(
          groupName: groupName,
          invitees: invitees,
          privacy: privacy,
          kind: kind,
          parentSpaceId: parentSpaceId,
        ),
      );

  NewGroupChatInfoState state() =>
      container.read(newGroupChatInfoControllerProvider);

  test('create_whenGroupInASpace_passesTheSpace', () async {
    // Act
    await create(parentSpaceId: '!space');

    // Assert
    final request =
        verify(mockRepository.createGroup(captureAny)).captured.single
            as CreateNewGroupChatRequest;
    expect(request.parentSpaceId, '!space');
  });

  test('create_whenSpaceRefusesTheGroup_tellsIt', () async {
    // Arrange
    when(
      mockRepository.createGroup(any),
    ).thenThrow(const SpaceForbiddenException());

    // Act
    await create(parentSpaceId: '!space');

    // Assert
    expect(
      state(),
      const NewGroupChatInfoState.failed(NewGroupFailureReason.spaceRefused),
    );
  });

  test('create_whenSpace_createsTheSpaceAndInvites', () async {
    // Arrange
    when(mockCreateSpaceUseCase.execute(any)).thenAnswer((_) async => roomId);

    // Act
    await create(
      groupName: 'Team',
      kind: NewGroupKind.space,
      parentSpaceId: '!parent',
    );

    // Assert
    verify(
      mockCreateSpaceUseCase.execute(
        const NewSpace(name: 'Team', parentSpaceId: '!parent'),
      ),
    ).called(1);
    verifyNever(mockRepository.createGroup(any));
    verify(
      mockRepository.inviteUser(roomId: roomId, userId: anyNamed('userId')),
    ).called(2);
    expect(state(), isA<NewGroupChatInfoDone>());
  });

  test('build_always_startsIdle', () {
    // Act
    final initial = state();

    // Assert
    expect(initial, const NewGroupChatInfoState.idle());
  });

  test('create_whenEncrypted_requestsAnEncryptedPrivateGroup', () async {
    // Act
    await create(privacy: const GroupPrivacyState(isEncrypted: true));

    // Assert
    final request =
        verify(mockRepository.createGroup(captureAny)).captured.single
            as CreateNewGroupChatRequest;
    expect(request.enableEncryption, isTrue);
    expect(request.isPublic, isFalse);
  });

  test('create_whenListenerClosesDuringCreation_stillInvites', () async {
    // Arrange
    final creation = Completer<String>();
    when(mockRepository.createGroup(any)).thenAnswer((_) => creation.future);

    // Act
    final created = create();
    await pumpEventQueue();
    subscription.close();
    await pumpEventQueue();
    creation.complete(roomId);
    await created;

    // Assert
    verify(
      mockRepository.inviteUser(roomId: roomId, userId: '@bob:example.com'),
    ).called(1);
    verify(
      mockRepository.inviteUser(roomId: roomId, userId: '@carol:example.com'),
    ).called(1);
  });

  test('create_whenNoInvitee_isDoneWithoutInviting', () async {
    // Act
    await create(groupName: 'Solo', invitees: const []);

    // Assert
    expect(
      state(),
      const NewGroupChatInfoState.done(roomId: roomId, groupName: 'Solo'),
    );
    verifyNever(
      mockRepository.inviteUser(
        roomId: anyNamed('roomId'),
        userId: anyNamed('userId'),
      ),
    );
  });

  test('create_whenGroupCreated_goesThroughCreatingAndInviting', () async {
    // Arrange
    final created = Completer<String>();
    when(mockRepository.createGroup(any)).thenAnswer((_) => created.future);

    // Act
    final future = create();
    final whileCreating = state();
    created.complete(roomId);
    await future;

    // Assert
    expect(whileCreating, const NewGroupChatInfoState.creating());
    expect(
      state(),
      const NewGroupChatInfoState.done(roomId: roomId, groupName: 'Team'),
    );
    verify(
      mockRepository.inviteUser(roomId: roomId, userId: '@bob:example.com'),
    ).called(1);
    verify(
      mockRepository.inviteUser(roomId: roomId, userId: '@carol:example.com'),
    ).called(1);
  });

  test('create_always_excludesTheCurrentUserFromTheInvitees', () async {
    // Arrange
    when(mockClient.userID).thenReturn('@alice:example.com');

    // Act
    await create(
      invitees: const ['@alice:example.com', '@bob:example.com', null],
    );

    // Assert
    final request =
        verify(mockRepository.createGroup(captureAny)).captured.single
            as CreateNewGroupChatRequest;
    expect(request.invite, ['@bob:example.com']);
  });

  test('create_whenSomeInvitesFail_isDoneWithTheFailures', () async {
    // Arrange
    const banned = UserBannedException(userId: '@bob:example.com');
    when(
      mockRepository.inviteUser(roomId: roomId, userId: '@bob:example.com'),
    ).thenThrow(banned);

    // Act
    await create();

    // Assert
    final done = state() as NewGroupChatInfoDone;
    expect(done.roomId, roomId);
    expect(done.inviteFailure?.failedUsers, {'@bob:example.com': banned});
  });

  test('create_whenGroupCreationFails_fails', () async {
    // Arrange
    when(
      mockRepository.createGroup(any),
    ).thenAnswer((_) => Future.error(Exception('Server error')));

    // Act
    await create();

    // Assert
    expect(
      state(),
      const NewGroupChatInfoState.failed(NewGroupFailureReason.other),
    );
  });

  test(
    'create_whenAnErrorIsThrownWhileInviting_isDoneWithEveryInviteeFailedAndRethrows',
    () async {
      // Arrange
      when(
        mockRepository.inviteUser(
          roomId: anyNamed('roomId'),
          userId: anyNamed('userId'),
        ),
      ).thenThrow(StateError('bug'));

      // Act & Assert
      await expectLater(create(), throwsStateError);
      final done = state() as NewGroupChatInfoDone;
      expect(done.roomId, roomId);
      expect(done.inviteFailure?.failedUsers, {
        '@bob:example.com': const GenericInviteException(
          userId: '@bob:example.com',
        ),
        '@carol:example.com': const GenericInviteException(
          userId: '@carol:example.com',
        ),
      });
    },
  );

  test('create_whenAnErrorIsThrownWhileCreating_failsAndRethrows', () async {
    // Arrange
    when(mockRepository.createGroup(any)).thenThrow(StateError('bug'));

    // Act & Assert
    await expectLater(create(), throwsStateError);
    expect(
      state(),
      const NewGroupChatInfoState.failed(NewGroupFailureReason.other),
    );
  });

  test('create_whenFeedCreated_invitesThenIsDone', () async {
    // Arrange
    when(
      mockFeedInteractor.execute(
        feedName: 'News',
        avatarUrl: 'mxc://example.com/avatar',
      ),
    ).thenAnswer((_) async => roomId);

    // Act
    await container
        .read(newGroupChatInfoControllerProvider.notifier)
        .create(
          const NewGroupForm(
            groupName: 'News',
            invitees: ['@bob:example.com'],
            privacy: GroupPrivacyState(),
            kind: NewGroupKind.feed,
            urlAvatar: 'mxc://example.com/avatar',
          ),
        );

    // Assert
    verify(
      mockRepository.inviteUser(roomId: roomId, userId: '@bob:example.com'),
    ).called(1);
    verifyNever(mockRepository.createGroup(any));
    expect(
      state(),
      const NewGroupChatInfoState.done(roomId: roomId, groupName: 'News'),
    );
  });

  test('create_whenFeedNotSupported_failsWithTheDedicatedReason', () async {
    // Arrange
    when(
      mockFeedInteractor.execute(
        feedName: anyNamed('feedName'),
        avatarUrl: anyNamed('avatarUrl'),
      ),
    ).thenAnswer(
      (_) => Future.error(const FeedNotSupportedByHomeserverException()),
    );

    // Act
    await create(kind: NewGroupKind.feed);

    // Assert
    expect(
      state(),
      const NewGroupChatInfoState.failed(
        NewGroupFailureReason.feedNotSupported,
      ),
    );
    verifyNever(mockRepository.createGroup(any));
  });

  test('create_whileCreating_isIgnored', () async {
    // Arrange
    final created = Completer<String>();
    when(mockRepository.createGroup(any)).thenAnswer((_) => created.future);
    final first = create();

    // Act
    await create();
    created.complete(roomId);
    await first;

    // Assert
    verify(mockRepository.createGroup(any)).called(1);
  });
}
