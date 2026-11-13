import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/data/repository/new_group/new_group_repository.provider.dart';
import 'package:twake_chat/domain/app_state/room/upload_content_state.dart';
import 'package:twake_chat/domain/exception/room/invite_user_exception.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';
import 'package:twake_chat/domain/repository/new_group/new_group_repository.dart';
import 'package:twake_chat/domain/spaces/new_space.dart';
import 'package:twake_chat/domain/spaces/usecases/create_space_usecase.dart';
import 'package:twake_chat/domain/spaces/usecases/create_space_usecase.provider.dart';
import 'package:twake_chat/domain/usecase/feed/create_new_feed_interactor.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_for_web_interactor.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_controller.dart';
import 'package:twake_chat/pages/new_group/providers/new_feed_providers.dart';
import 'package:twake_chat/pages/new_group/states/group_privacy_state.dart';
import 'package:twake_chat/pages/new_group/states/new_group_form.dart';
import 'package:twake_chat/pages/new_group/states/new_group_kind.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import 'new_group_chat_info_flow_test.mocks.dart';
import '../../providers/fake_active_account.dart';

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<NewGroupRepository>(),
  MockSpec<UploadContentInteractor>(),
  MockSpec<UploadContentInBytesInteractor>(),
  MockSpec<CreateNewFeedInteractor>(),
  MockSpec<CreateSpaceUseCase>(),
])
void main() {
  provideDummy<NewSpace>(const NewSpace(name: ''));

  const roomId = '!room:example.com';
  const bob = '@bob:example.com';
  const avatarUrl = 'mxc://example.com/avatar';

  final uploadInteractor = MockUploadContentInteractor();
  final uploadInBytesInteractor = MockUploadContentInBytesInteractor();
  late MockClient mockClient;
  late MockNewGroupRepository mockRepository;
  late MockCreateNewFeedInteractor mockFeedInteractor;
  late MockCreateSpaceUseCase mockCreateSpaceUseCase;

  setUpAll(() {
    GetIt.instance
      ..registerSingleton(ResponsiveUtils())
      ..registerSingleton<UploadContentInteractor>(uploadInteractor)
      ..registerSingleton<UploadContentInBytesInteractor>(
        uploadInBytesInteractor,
      );
  });

  tearDownAll(() => GetIt.instance.reset());

  setUp(() {
    reset(uploadInBytesInteractor);
    mockClient = MockClient();
    mockRepository = MockNewGroupRepository();
    when(mockRepository.createGroup(any)).thenAnswer((_) async => roomId);
    mockFeedInteractor = MockCreateNewFeedInteractor();
    when(
      mockFeedInteractor.execute(
        feedName: anyNamed('feedName'),
        avatarUrl: anyNamed('avatarUrl'),
      ),
    ).thenAnswer((_) async => roomId);
    mockCreateSpaceUseCase = MockCreateSpaceUseCase();
    when(mockCreateSpaceUseCase.execute(any)).thenAnswer((_) async => roomId);
  });

  Future<void> pumpRouter(
    WidgetTester tester,
    GoRouter router, {
    Size size = const Size(411, 914),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...activeAccountOverrides(mockClient),
          newGroupRepositoryProvider.overrideWithValue(mockRepository),
          createSpaceUseCaseProvider.overrideWithValue(mockCreateSpaceUseCase),
          createNewFeedInteractorProvider.overrideWithValue(mockFeedInteractor),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<NewGroupChatInfoScreenState> pumpScreen(WidgetTester tester) async {
    await pumpRouter(
      tester,
      GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const NewGroupChatInfo(contactsList: {}),
          ),
          GoRoute(
            path: '/rooms/:roomid',
            builder: (_, state) =>
                Text('room ${state.pathParameters['roomid']}'),
          ),
        ],
      ),
    );
    final screen = tester.state<NewGroupChatInfoScreenState>(
      find.byType(NewGroupChatInfo),
    );
    screen.groupNameTextEditingController.text = 'Team';
    return screen;
  }

  const chatList = 'chat list';

  // As in the app on web and desktop: the chat list column holds its own
  // navigator (contacts, then this screen pushed on it); the room opens over
  // it, here full screen whatever the width so that no layout overflows.
  Future<void> pumpInFirstColumn(
    WidgetTester tester, {
    required Size size,
    required NewGroupKind kind,
  }) => pumpRouter(
    tester,
    size: size,
    GoRouter(
      routes: [
        ShellRoute(
          builder: (_, _, child) => Stack(
            fit: StackFit.expand,
            children: [
              Navigator(
                onGenerateRoute: (_) => null,
                onGenerateInitialRoutes: (_, _) => [
                  MaterialPageRoute<void>(builder: (_) => const Text(chatList)),
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        NewGroupChatInfo(contactsList: const {}, kind: kind),
                  ),
                ],
              ),
              child,
            ],
          ),
          routes: [
            GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
            GoRoute(
              path: '/rooms/:roomid',
              builder: (_, state) =>
                  Text('room ${state.pathParameters['roomid']}'),
            ),
          ],
        ),
      ],
    ),
  );

  L10n l10nOf(WidgetTester tester) =>
      L10n.of(tester.element(find.byType(Navigator).first))!;

  void stubUpload(Either<Failure, Success> result) =>
      when(
        uploadInBytesInteractor.execute(
          matrixClient: anyNamed('matrixClient'),
          matrixFile: anyNamed('matrixFile'),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([Right(UploadContentLoading()), result]),
      );

  // The participant tiles need the whole Matrix widget, so the invitee is
  // passed to the controller instead of through the screen's contacts.
  void createWithBob(
    WidgetTester tester, {
    NewGroupKind kind = NewGroupKind.group,
  }) => unawaited(
    ProviderScope.containerOf(tester.element(find.byType(NewGroupChatInfo)))
        .read(newGroupChatInfoControllerProvider.notifier)
        .create(
          NewGroupForm(
            groupName: 'Team',
            invitees: const [bob],
            privacy: const GroupPrivacyState(),
            kind: kind,
          ),
        ),
  );

  CreateNewGroupChatRequest createdRequest() =>
      verify(mockRepository.createGroup(captureAny)).captured.single
          as CreateNewGroupChatRequest;

  group('NewGroupChatInfoScreenState avatar upload', () {
    testWidgets('moveToGroupChatScreen_whenUploaded_createsWithTheAvatar', (
      tester,
    ) async {
      // Arrange
      final screen = await pumpScreen(tester);
      stubUpload(Right(UploadContentSuccess(uri: Uri.parse(avatarUrl))));
      screen.updateAvatarFilePicker(
        MatrixFile(bytes: Uint8List(1), name: 'avatar.png'),
      );

      // Act
      screen.moveToGroupChatScreen();
      await tester.pumpAndSettle();

      // Assert
      expect(createdRequest().urlAvatar, avatarUrl);
    });

    testWidgets(
      'moveToGroupChatScreen_whenUploadFailsAndUserContinues_createsWithoutAvatar',
      (tester) async {
        // Arrange
        final screen = await pumpScreen(tester);
        stubUpload(Left(UploadContentFailed(exception: Exception('upload'))));
        screen.updateAvatarFilePicker(
          MatrixFile(bytes: Uint8List(1), name: 'avatar.png'),
        );
        screen.moveToGroupChatScreen();
        await tester.pumpAndSettle();
        final l10n = l10nOf(tester);
        verifyNever(mockRepository.createGroup(any));

        // Act
        await tester.tap(find.text(l10n.continueProcess));
        await tester.pumpAndSettle();

        // Assert
        expect(createdRequest().urlAvatar, isNull);
      },
    );
  });

  group('NewGroupChatInfoScreenState busy', () {
    testWidgets('createNewGroup_whileCreating_disablesTheFormAndShowsALoader', (
      tester,
    ) async {
      // Arrange
      await pumpScreen(tester);
      final created = Completer<String>();
      when(mockRepository.createGroup(any)).thenAnswer((_) => created.future);

      // Act
      createWithBob(tester);
      await tester.pump();
      final nameFieldEnabled = tester
          .widget<TextField>(find.byType(TextField))
          .enabled;
      final loaderShown = find
          .byType(CircularProgressIndicator)
          .evaluate()
          .isNotEmpty;
      final doneButtonShown = find.byIcon(Icons.done).evaluate().isNotEmpty;
      created.complete(roomId);
      await tester.pumpAndSettle();

      // Assert
      expect(nameFieldEnabled, isFalse);
      expect(loaderShown, isTrue);
      expect(doneButtonShown, isFalse);
    });
  });

  group('NewGroupChatInfoScreenState done', () {
    testWidgets(
      'createNewGroup_whenSomeInvitesFail_opensTheRoomAfterTheDialog',
      (tester) async {
        // Arrange
        await pumpScreen(tester);
        when(
          mockRepository.inviteUser(roomId: roomId, userId: bob),
        ).thenThrow(const UserBannedException(userId: bob));

        // Act
        createWithBob(tester);
        await tester.pumpAndSettle();
        final l10n = l10nOf(tester);
        final roomOpenedBeforeDialogClosed = find
            .text('room $roomId')
            .evaluate()
            .isNotEmpty;
        final dialogShown = find.text(l10n.gotIt).evaluate().isNotEmpty;
        await tester.tap(find.text(l10n.gotIt));
        await tester.pumpAndSettle();

        // Assert
        expect(dialogShown, isTrue);
        expect(roomOpenedBeforeDialogClosed, isFalse);
        expect(find.text('room $roomId'), findsOneWidget);
      },
    );

    testWidgets('createNewGroup_whenEveryoneIsInvited_opensTheRoom', (
      tester,
    ) async {
      // Arrange
      await pumpScreen(tester);

      // Act
      createWithBob(tester);
      await tester.pumpAndSettle();

      // Assert
      verify(mockRepository.inviteUser(roomId: roomId, userId: bob)).called(1);
      expect(find.text('room $roomId'), findsOneWidget);
    });
  });

  group('NewGroupChatInfoScreenState done, first column navigator', () {
    const sizes = {
      'SingleColumn': Size(411, 914),
      'TwoColumns': Size(1280, 900),
    };
    String capitalized(String word) =>
        word[0].toUpperCase() + word.substring(1);
    for (final MapEntry(key: layout, value: size) in sizes.entries) {
      for (final kind in NewGroupKind.values) {
        testWidgets(
          'createNewGroup_when${capitalized(kind.name)}CreatedIn${layout}_'
          'closesTheInnerScreensAndOpensTheRoom',
          (tester) async {
            // Arrange
            await pumpInFirstColumn(tester, size: size, kind: kind);
            expect(find.byType(NewGroupChatInfo), findsOneWidget);

            // Act
            createWithBob(tester, kind: kind);
            await tester.pumpAndSettle();

            // Assert
            expect(find.byType(NewGroupChatInfo), findsNothing);
            expect(find.text(chatList), findsOneWidget);
            expect(find.text('room $roomId'), findsOneWidget);
          },
        );
      }
    }
  });
}
