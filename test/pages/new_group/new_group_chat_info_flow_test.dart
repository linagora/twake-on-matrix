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
import 'package:twake_chat/domain/usecase/room/upload_content_for_web_interactor.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_controller.dart';
import 'package:twake_chat/pages/new_group/states/group_privacy_state.dart';
import 'package:twake_chat/pages/new_group/states/new_group_form.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import 'new_group_chat_info_flow_test.mocks.dart';
import '../../providers/fake_active_account.dart';

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<NewGroupRepository>(),
  MockSpec<UploadContentInteractor>(),
  MockSpec<UploadContentInBytesInteractor>(),
])
void main() {
  const roomId = '!room:example.com';
  const bob = '@bob:example.com';
  const avatarUrl = 'mxc://example.com/avatar';

  final uploadInteractor = MockUploadContentInteractor();
  final uploadInBytesInteractor = MockUploadContentInBytesInteractor();
  late MockClient mockClient;
  late MockNewGroupRepository mockRepository;

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
  });

  Future<NewGroupChatInfoScreenState> pumpScreen(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(411, 914);
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const NewGroupChatInfo(contactsList: {}),
        ),
        GoRoute(
          path: '/rooms/:roomid',
          builder: (_, state) => Text('room ${state.pathParameters['roomid']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...activeAccountOverrides(mockClient),
          newGroupRepositoryProvider.overrideWithValue(mockRepository),
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
    final screen = tester.state<NewGroupChatInfoScreenState>(
      find.byType(NewGroupChatInfo),
    );
    screen.groupNameTextEditingController.text = 'Team';
    return screen;
  }

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
  void createWithBob(WidgetTester tester) => unawaited(
    ProviderScope.containerOf(tester.element(find.byType(NewGroupChatInfo)))
        .read(newGroupChatInfoControllerProvider.notifier)
        .create(
          const NewGroupForm(
            groupName: 'Team',
            invitees: [bob],
            privacy: GroupPrivacyState(),
            isFeed: false,
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
}
