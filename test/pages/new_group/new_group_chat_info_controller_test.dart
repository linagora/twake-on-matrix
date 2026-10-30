import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/repository/new_group/new_group_repository.provider.dart';
import 'package:twake_chat/domain/exception/feed/feed_exception.dart';
import 'package:twake_chat/domain/exception/room/invite_user_exception.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';
import 'package:twake_chat/domain/repository/new_group/new_group_repository.dart';
import 'package:twake_chat/domain/usecase/feed/create_new_feed_interactor.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_controller.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_state.dart';
import 'package:twake_chat/pages/new_group/providers/new_feed_providers.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

import 'new_group_chat_info_controller_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<NewGroupRepository>(),
  MockSpec<CreateNewFeedInteractor>(),
])
void main() {
  const roomId = '!room:example.com';
  const request = CreateNewGroupChatRequest(
    groupName: 'Team',
    invite: ['@bob:example.com', '@carol:example.com'],
  );

  late MockClient mockClient;
  late MockNewGroupRepository mockRepository;
  late MockCreateNewFeedInteractor mockFeedInteractor;
  late ProviderContainer container;
  late ProviderSubscription<NewGroupChatInfoState> subscription;

  setUp(() {
    mockClient = MockClient();
    mockRepository = MockNewGroupRepository();
    mockFeedInteractor = MockCreateNewFeedInteractor();
    when(mockRepository.createGroup(any)).thenAnswer((_) async => roomId);
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        activeMatrixClientProvider.overrideWithBuild(
          (_, _) => ActiveClientSnapshot(mockClient),
        ),
        newGroupRepositoryProvider.overrideWithValue(mockRepository),
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

  NewGroupChatInfoController controller() =>
      container.read(newGroupChatInfoControllerProvider.notifier);

  NewGroupChatInfoState state() =>
      container.read(newGroupChatInfoControllerProvider);

  test('build_always_startsIdle', () {
    // Act
    final initial = state();

    // Assert
    expect(initial, const NewGroupChatInfoState.idle());
  });

  test('create_whenNoInvitee_isDoneWithoutInviting', () async {
    // Act
    await controller().create(
      const CreateNewGroupChatRequest(groupName: 'Solo'),
      isFeed: false,
    );

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
    final future = controller().create(request, isFeed: false);
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

  test('create_whenSomeInvitesFail_isDoneWithTheFailures', () async {
    // Arrange
    const banned = UserBannedException(userId: '@bob:example.com');
    when(
      mockRepository.inviteUser(roomId: roomId, userId: '@bob:example.com'),
    ).thenThrow(banned);

    // Act
    await controller().create(request, isFeed: false);

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
    await controller().create(request, isFeed: false);

    // Assert
    expect(
      state(),
      const NewGroupChatInfoState.failed(NewGroupFailureReason.other),
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
    await controller().create(request, isFeed: true);

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
    final first = controller().create(request, isFeed: false);

    // Act
    await controller().create(request, isFeed: false);
    created.complete(roomId);
    await first;

    // Assert
    verify(mockRepository.createGroup(any)).called(1);
  });
}
